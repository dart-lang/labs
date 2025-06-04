// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:path/path.dart' as p;

import 'file_system.dart';
import 'internal_constants.dart';
import 'libc.dart' as libc;

/// The default `mode` to use with `open` calls that may create a file.
const _defaultMode = 438; // => 0666 => rw-rw-rw-

/// The default `mode` to use when creating a directory.
const _defaultDirectoryMode = 511; // => 0777 => rwxrwxrwx

const _nanosecondsPerSecond = 1000000000;

bool _isDotOrDotDot(Pointer<Char> s) => // ord('.') == 46
    s[0] == 46 && ((s[1] == 0) || (s[1] == 46 && s[2] == 0));

Exception _getError(int err, String message, String path) {
  // TODO(brianquinlan): In the long-term, do we need to avoid exceptions that
  // are part of `dart:io`? Can we move those exceptions into a different
  // namespace?
  final osError = io.OSError(
    libc.strerror(err).cast<ffi.Utf8>().toDartString(),
    err,
  );

  if (err == libc.EPERM || err == libc.EACCES) {
    return io.PathAccessException(path, osError, message);
  } else if (err == libc.EEXIST) {
    return io.PathExistsException(path, osError, message);
  } else if (err == libc.ENOENT) {
    return io.PathNotFoundException(path, osError, message);
  } else {
    return io.FileSystemException(message, path, osError);
  }
}

/// Return the given function until the result is not `EINTR`.
int _tempFailureRetry(int Function() f) {
  int result;
  do {
    result = f();
  } while (result == -1 && libc.errno == libc.EINTR);
  return result;
}

/// Information about a directory, link, etc. stored in the [PosixFileSystem].
final class PosixMetadata implements Metadata {
  /// The `st_mode` field of the POSIX stat struct.
  ///
  /// See [stat.h](https://pubs.opengroup.org/onlinepubs/009696799/basedefs/sys/stat.h.html)
  /// for information on how to interpret this field.
  final int mode;
  final int _flags;

  @override
  final int size;

  /// The time that the file system object was last accessed in nanoseconds
  /// since the epoch.
  ///
  /// Access time is updated when the object is read or modified.
  ///
  /// The resolution of the access time varies by platform and file system.
  final int accessedTimeNanos;

  /// The time that the file system object was created in nanoseconds since the
  /// epoch.
  ///
  /// This will always be `null` on Android and Linux.
  ///
  /// The resolution of the creation time varies by platform and file system.
  final int? creationTimeNanos;

  /// The time that the file system object was last modified in nanoseconds
  /// since the epoch.
  ///
  /// The resolution of the modification time varies by platform and file
  /// system.
  final int modificationTimeNanos;

  int get _fmt => mode & libc.S_IFMT;

  @override
  FileSystemType get type {
    if (_fmt == libc.S_IFBLK) {
      return FileSystemType.block;
    }
    if (_fmt == libc.S_IFCHR) {
      return FileSystemType.character;
    }
    if (_fmt == libc.S_IFDIR) {
      return FileSystemType.directory;
    }
    if (_fmt == libc.S_IFREG) {
      return FileSystemType.file;
    }
    if (_fmt == libc.S_IFLNK) {
      return FileSystemType.link;
    }
    if (_fmt == libc.S_IFIFO) {
      return FileSystemType.pipe;
    }
    if (_fmt == libc.S_IFSOCK) {
      return FileSystemType.socket;
    }
    return FileSystemType.unknown;
  }

  @override
  bool get isDirectory => type == FileSystemType.directory;

  @override
  bool get isFile => type == FileSystemType.file;

  @override
  bool get isLink => type == FileSystemType.link;

  @override
  DateTime get access =>
      DateTime.fromMicrosecondsSinceEpoch(accessedTimeNanos ~/ 1000);

  @override
  DateTime? get creation =>
      creationTimeNanos == null
          ? null
          : DateTime.fromMicrosecondsSinceEpoch(creationTimeNanos! ~/ 1000);

  @override
  DateTime get modification =>
      DateTime.fromMicrosecondsSinceEpoch(modificationTimeNanos ~/ 1000);

  @override
  bool? get isHidden {
    if (io.Platform.isIOS || io.Platform.isMacOS) {
      return _flags & libc.UF_HIDDEN != 0;
    }
    return null;
  }

  PosixMetadata._(
    this.mode,
    this._flags,
    this.size,
    this.accessedTimeNanos,
    this.creationTimeNanos,
    this.modificationTimeNanos,
  );

  /// Construct [PosixMetadata] from data returned by the `stat` system call.
  factory PosixMetadata.fromFileAttributes({
    required int mode,
    int flags = 0,
    int size = 0,
    int accessedTimeNanos = 0,
    int? creationTimeNanos,
    int modificationTimeNanos = 0,
  }) => PosixMetadata._(
    mode,
    flags,
    size,
    accessedTimeNanos,
    creationTimeNanos,
    modificationTimeNanos,
  );

  @override
  bool operator ==(Object other) =>
      other is PosixMetadata &&
      mode == other.mode &&
      _flags == other._flags &&
      size == other.size &&
      accessedTimeNanos == other.accessedTimeNanos &&
      creationTimeNanos == other.creationTimeNanos &&
      modificationTimeNanos == other.modificationTimeNanos;

  @override
  int get hashCode => Object.hash(
    mode,
    _flags,
    size,
    accessedTimeNanos,
    creationTimeNanos,
    modificationTimeNanos,
  );
}

/// The POSIX `read` function.
///
/// See https://pubs.opengroup.org/onlinepubs/9699919799/functions/read.html
@Native<Int Function(Int, Pointer<Uint8>, Int)>(isLeaf: false)
external int read(int fd, Pointer<Uint8> buf, int count);

/// The POSIX `write` function.
///
/// See https://pubs.opengroup.org/onlinepubs/9699919799/functions/write.html
@Native<Int Function(Int, Pointer<Uint8>, Int)>(isLeaf: false)
external int write(int fd, Pointer<Uint8> buf, int count);

/// A [FileSystem] implementation for POSIX systems (e.g. Android, iOS, Linux,
/// macOS).
final class PosixFileSystem extends FileSystem {
  @override
  bool same(String path1, String path2) => ffi.using((arena) {
    final stat1 = arena<libc.Stat>();
    if (libc.stat(path1.toNativeUtf8(allocator: arena).cast(), stat1) == -1) {
      final errno = libc.errno;
      throw _getError(errno, 'stat failed', path1);
    }

    final stat2 = arena<libc.Stat>();
    if (libc.stat(path2.toNativeUtf8(allocator: arena).cast(), stat2) == -1) {
      final errno = libc.errno;
      throw _getError(errno, 'stat failed', path2);
    }

    return (stat1.ref.st_ino == stat2.ref.st_ino) &&
        (stat1.ref.st_dev == stat2.ref.st_dev);
  });

  @override
  void createDirectory(String path) => ffi.using((arena) {
    if (libc.mkdir(
          path.toNativeUtf8(allocator: arena).cast(),
          _defaultDirectoryMode,
        ) ==
        -1) {
      final errno = libc.errno;
      throw _getError(errno, 'create directory failed', path);
    }
  });

  @override
  String createTemporaryDirectory({String? parent, String? prefix}) =>
      ffi.using((arena) {
        final directory = parent ?? temporaryDirectory;
        final template = p.join(directory, '${prefix ?? ''}XXXXXX');

        final path = libc.mkdtemp(
          template.toNativeUtf8(allocator: arena).cast(),
        );
        if (path == nullptr) {
          final errno = libc.errno;
          throw _getError(errno, 'mkdtemp failed', template);
        }
        return path.cast<ffi.Utf8>().toDartString();
      });

  @override
  PosixMetadata metadata(String path) => ffi.using((arena) {
    final stat = arena<libc.Stat>();

    if (libc.lstat(path.toNativeUtf8(allocator: arena).cast(), stat) == -1) {
      final errno = libc.errno;
      throw _getError(errno, 'stat failed', path);
    }

    return PosixMetadata.fromFileAttributes(
      mode: stat.ref.st_mode,
      flags: stat.ref.st_flags,
      size: stat.ref.st_size,
      accessedTimeNanos:
          stat.ref.st_atim.tv_sec * _nanosecondsPerSecond +
          stat.ref.st_atim.tv_sec,
      creationTimeNanos:
          stat.ref.st_btime.tv_sec * _nanosecondsPerSecond +
          stat.ref.st_btime.tv_sec,
      modificationTimeNanos:
          stat.ref.st_mtim.tv_sec * _nanosecondsPerSecond +
          stat.ref.st_mtim.tv_sec,
    );
  });

  @override
  void removeDirectory(String path) => ffi.using((arena) {
    if (libc.unlinkat(
          libc.AT_FDCWD,
          path.toNativeUtf8(allocator: arena).cast(),
          libc.AT_REMOVEDIR,
        ) ==
        -1) {
      final errno = libc.errno;
      throw _getError(errno, 'remove directory failed', path);
    }
  });

  void _removeDirectoryTree(
    int parentfd,
    String parentPath,
    Pointer<ffi.Utf8> name,
  ) => ffi.using((arena) {
    late final path = p.join(parentPath, name.toDartString());
    late final stat = arena<libc.Stat>();

    final fd = _tempFailureRetry(
      () => libc.openat(parentfd, name.cast(), libc.O_DIRECTORY, 0),
    );
    if (fd == -1) {
      final errno = libc.errno;
      throw _getError(errno, 'openat failed', path);
    }
    try {
      final dir = libc.fdopendir(fd);
      if (dir == nullptr) {
        final errno = libc.errno;
        throw _getError(errno, 'fdopendir failed', path);
      }
      try {
        // `readdir` returns `NULL` but leaves `errno` unchanged if the end of
        // the directory stream is reached.
        libc.errno = 0;
        var dirent = libc.readdir(dir);

        while (dirent != nullptr) {
          final child = libc.d_name_ptr(dirent);
          late final childPath = p.join(
            parentPath,
            name.toDartString(),
            child.cast<ffi.Utf8>().toDartString(),
          );

          if (_isDotOrDotDot(child)) {
            libc.errno = 0;
            dirent = libc.readdir(dir);
            continue;
          }
          var type = dirent.ref.d_type;
          if (type == libc.DT_UNKNOWN) {
            /// From https://man7.org/linux/man-pages/man2/getdents.2.html:
            /// Currently, only some filesystems (among them: Btrfs, ext2, ext3,
            /// and ext4) have full support for returning the file type in
            /// d_type. All applications must properly handle a return of
            /// DT_UNKNOWN.
            if (libc.fstatat(fd, child, stat, libc.AT_SYMLINK_NOFOLLOW) == -1) {
              final errno = libc.errno;
              throw _getError(errno, 'fstatat failed', childPath);
            }
            type =
                stat.ref.st_mode & libc.S_IFMT == libc.S_IFDIR
                    ? libc.DT_DIR
                    : libc.DT_REG;
          }
          if (type == libc.DT_DIR) {
            _removeDirectoryTree(fd, path, child.cast());
          } else {
            if (libc.unlinkat(fd, child, 0) == -1) {
              final errno = libc.errno;
              throw _getError(errno, 'unlinkat failed', childPath);
            }
          }
          libc.errno = 0;
          dirent = libc.readdir(dir);
        }
        if (libc.errno != 0) {
          final errno = libc.errno;
          throw _getError(errno, 'readdir failed', path);
        }
        if (libc.unlinkat(parentfd, name.cast(), libc.AT_REMOVEDIR) == -1) {
          final errno = libc.errno;
          throw _getError(errno, 'unlinkat failed', path);
        }
      } finally {
        libc.closedir(dir);
      }
    } finally {
      libc.close(fd);
    }
  });

  @override
  void removeDirectoryTree(String path) => ffi.using((arena) {
    _removeDirectoryTree(
      libc.AT_FDCWD,
      '.',
      path.toNativeUtf8(allocator: arena),
    );
  });

  @override
  void rename(String oldPath, String newPath) => ffi.using((arena) {
    // See https://pubs.opengroup.org/onlinepubs/000095399/functions/rename.html
    if (libc.rename(
          oldPath.toNativeUtf8(allocator: arena).cast(),
          newPath.toNativeUtf8(allocator: arena).cast(),
        ) !=
        0) {
      final errno = libc.errno;
      throw _getError(errno, 'rename failed', oldPath);
    }
  });

  @override
  Uint8List readAsBytes(String path) => ffi.using((arena) {
    final fd = _tempFailureRetry(
      () => libc.open(
        path.toNativeUtf8(allocator: arena).cast(),
        libc.O_RDONLY | libc.O_CLOEXEC,
        0,
      ),
    );
    if (fd == -1) {
      final errno = libc.errno;
      throw _getError(errno, 'open failed', path);
    }
    try {
      final stat = arena<libc.Stat>();
      // The POSIX specification only defines the meaning of `st_size` for
      // regular files and symbolic links.
      if (libc.fstat(fd, stat) != -1 && stat.ref.st_mode & libc.S_IFREG != 0) {
        if (stat.ref.st_size == 0) {
          return Uint8List(0);
        } else {
          return _readKnownLength(path, fd, stat.ref.st_size);
        }
      }
      return _readUnknownLength(path, fd);
    } finally {
      libc.close(fd);
    }
  });

  Uint8List _readUnknownLength(String path, int fd) => ffi.using((arena) {
    final buffer = arena<Uint8>(blockSize);
    final builder = BytesBuilder(copy: true);

    while (true) {
      final r = _tempFailureRetry(() => read(fd, buffer, blockSize));
      switch (r) {
        case -1:
          final errno = libc.errno;
          throw _getError(errno, 'read failed', path);
        case 0:
          return builder.takeBytes();
        default:
          final typed = buffer.asTypedList(r);
          builder.add(typed);
      }
    }
  });

  Uint8List _readKnownLength(String path, int fd, int length) {
    // In the happy path, `buffer` will be returned to the caller as a
    // `Uint8List`. If there in an exception, free it and rethrow the exception.
    final buffer = ffi.malloc<Uint8>(length);
    try {
      var bufferOffset = 0;

      while (bufferOffset < length) {
        final r = _tempFailureRetry(
          () => read(
            fd,
            (buffer + bufferOffset).cast(),
            min(length - bufferOffset, maxReadSize),
          ),
        );
        switch (r) {
          case -1:
            final errno = libc.errno;
            throw _getError(errno, 'read failed', path);
          case 0:
            return buffer.asTypedList(
              bufferOffset,
              finalizer: ffi.calloc.nativeFree,
            );
          default:
            bufferOffset += r;
        }
      }
      return buffer.asTypedList(length, finalizer: ffi.calloc.nativeFree);
    } on Exception {
      ffi.malloc.free(buffer);
      rethrow;
    }
  }

  @override
  String get temporaryDirectory => ffi.using((arena) {
    var env = libc.getenv('TMPDIR'.toNativeUtf8(allocator: arena).cast());
    if (env == nullptr) {
      env = libc.getenv('TMP'.toNativeUtf8(allocator: arena).cast());
    }
    late String tmp;
    if (env == nullptr) {
      tmp = io.Platform.isAndroid ? '/data/local/tmp' : '/tmp';
    } else {
      tmp = env.cast<ffi.Utf8>().toDartString();
    }
    return p.canonicalize(tmp);
  });

  @override
  void writeAsBytes(
    String path,
    Uint8List data, [
    WriteMode mode = WriteMode.failExisting,
  ]) => ffi.using((arena) {
    var flags = libc.O_WRONLY | libc.O_CLOEXEC;

    flags |= switch (mode) {
      WriteMode.appendExisting => libc.O_CREAT | libc.O_APPEND,
      WriteMode.failExisting => libc.O_CREAT | libc.O_EXCL,
      WriteMode.truncateExisting => libc.O_CREAT | libc.O_TRUNC,
      _ => throw ArgumentError.value(mode, 'invalid write mode'),
    };

    final fd = _tempFailureRetry(
      () => libc.open(
        path.toNativeUtf8(allocator: arena).cast(),
        flags,
        _defaultMode,
      ),
    );
    try {
      if (fd == -1) {
        final errno = libc.errno;
        throw _getError(errno, 'open failed', path);
      }

      ffi.using((arena) {
        // TODO(brianquinlan): Remove this copy when typed data pointers are
        // available for non-leaf calls.
        var buffer = arena<Uint8>(data.length);
        buffer.asTypedList(data.length).setAll(0, data);
        var remaining = data.length;

        while (remaining > 0) {
          final w = _tempFailureRetry(
            () =>
                write(fd, buffer, min(remaining, min(maxWriteSize, remaining))),
          );
          if (w == -1) {
            final errno = libc.errno;
            throw _getError(errno, 'write failed', path);
          }
          remaining -= w;
          buffer += w;
        }
      });
    } finally {
      libc.close(fd);
    }
  });

  @override
  void writeAsString(
    String path,
    String contents, [
    WriteMode mode = WriteMode.failExisting,
    Encoding encoding = utf8,
    String? lineTerminator,
  ]) {
    lineTerminator ??= '\n';
    final List<int> data;
    if (lineTerminator == '\n') {
      data = encoding.encode(contents);
    } else if (lineTerminator == '\r\n') {
      data = encoding.encode(contents.replaceAll('\n', '\r\n'));
    } else {
      throw ArgumentError.value(lineTerminator, 'lineTerminator');
    }
    writeAsBytes(
      path,
      data is Uint8List ? data : Uint8List.fromList(data),
      mode,
    );
  }
}
