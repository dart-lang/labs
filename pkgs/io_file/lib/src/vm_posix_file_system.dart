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

Exception _getError(int err, String message, [String? path]) {
  //TODO(brianquinlan): In the long-term, do we need to avoid exceptions that
  // are part of `dart:io`? Can we move those exceptions into a different
  // namespace?
  final osError = io.OSError(
    libc.strerror(err).cast<ffi.Utf8>().toDartString(),
    err,
  );

  if (path != null) {
    if (err == libc.EPERM || err == libc.EACCES) {
      return io.PathAccessException(path, osError, message);
    } else if (err == libc.EEXIST) {
      return io.PathExistsException(path, osError, message);
    } else if (err == libc.ENOENT) {
      return io.PathNotFoundException(path, osError, message);
    } else {
      return io.FileSystemException(message, path, osError);
    }
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
base class PosixFileSystem extends FileSystem {
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
  set currentDirectory(String path) => ffi.using((arena) {
    if (libc.chdir(path.toNativeUtf8(allocator: arena).cast()) == -1) {
      final errno = libc.errno;
      throw _getError(errno, 'chdir failed', path);
    }
  });

  @override
  String get currentDirectory => ffi.using((arena) {
    final buffer = arena<Char>(libc.PATH_MAX);
    if (libc.getcwd(buffer, libc.PATH_MAX) == nullptr) {
      final errno = libc.errno;
      throw _getError(errno, 'getcwd failed', null);
    }
    return buffer.cast<ffi.Utf8>().toDartString();
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
