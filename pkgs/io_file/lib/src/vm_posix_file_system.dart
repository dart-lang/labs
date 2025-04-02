// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:stdlibc/stdlibc.dart' as stdlibc;

import 'file_system.dart';
import 'internal_constants.dart';

const _maxInt32 = 2147483647;

/// The default `mode` to use with `open` calls that may create a file.
const _defaultMode = 438; // => 0666 => rw-rw-rw-

Exception _getError(int errno, String message, String path) {
  //TODO(brianquinlan): In the long-term, do we need to avoid exceptions that
  // are part of `dart:io`? Can we move those exceptions into a different
  // namespace?
  final osError = io.OSError(stdlibc.strerror(errno) ?? '', errno);

  if (errno == stdlibc.EPERM || errno == stdlibc.EACCES) {
    return io.PathAccessException(path, osError, message);
  } else if (errno == stdlibc.EEXIST) {
    return io.PathExistsException(path, osError, message);
  } else if (errno == stdlibc.ENOENT) {
    return io.PathNotFoundException(path, osError, message);
  } else {
    return io.FileSystemException(message, path, osError);
  }
}

/// Return the given function until the result is not `EINTR`.
int _tempFailureRetry(int Function() f) {
  int result;
  var errno = 0;
  do {
    result = f();
    errno = stdlibc.errno;
    if (result == -1 && errno != 0) {
      print('unexpected errno: $errno');
    }
  } while (result == -1 && errno == stdlibc.EINTR);
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
  void rename(String oldPath, String newPath) {
    // See https://pubs.opengroup.org/onlinepubs/000095399/functions/rename.html
    if (stdlibc.rename(oldPath, newPath) != 0) {
      final errno = stdlibc.errno;
      throw _getError(errno, 'rename failed', oldPath);
    }
  }

  @override
  Uint8List readAsBytes(String path) {
    final fd = _tempFailureRetry(
      () => stdlibc.open(path, flags: stdlibc.O_RDONLY | stdlibc.O_CLOEXEC),
    );
    if (fd == -1) {
      final errno = stdlibc.errno;
      throw _getError(errno, 'open failed', path);
    }
    try {
      final stat = stdlibc.fstat(fd);
      // The POSIX specification only defines the meaning of `st_size` for
      // regular files and symbolic links.
      if (stat != null && stat.st_mode & stdlibc.S_IFREG != 0) {
        if (stat.st_size == 0) {
          return Uint8List(0);
        } else {
          return _readKnownLength(path, fd, stat.st_size);
        }
      }
      return _readUnknownLength(path, fd);
    } finally {
      stdlibc.close(fd);
    }
  }

  Uint8List _readUnknownLength(String path, int fd) => ffi.using((arena) {
    final buffer = arena<Uint8>(blockSize);
    final builder = BytesBuilder(copy: true);

    while (true) {
      final r = _tempFailureRetry(() => read(fd, buffer, blockSize));
      switch (r) {
        case -1:
          final errno = stdlibc.errno;
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
            final errno = stdlibc.errno;
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
  void writeAsBytes(
    String path,
    Uint8List data, [
    WriteMode mode = WriteMode.failExisting,
  ]) {
    var flags = stdlibc.O_WRONLY | stdlibc.O_CLOEXEC;

    flags |= switch (mode) {
      WriteMode.appendExisting => stdlibc.O_CREAT | stdlibc.O_APPEND,
      WriteMode.failExisting => stdlibc.O_CREAT | stdlibc.O_EXCL,
      WriteMode.truncateExisting => stdlibc.O_CREAT | stdlibc.O_TRUNC,
      _ => throw ArgumentError.value(mode, 'invalid write mode'),
    };

    final fd = _tempFailureRetry(
      () => stdlibc.open(path, flags: flags, mode: _defaultMode),
    );
    try {
      if (fd == -1) {
        final errno = stdlibc.errno;
        throw _getError(errno, 'open failed', path);
      }

      ffi.using((arena) {
        // TODO(brianquinlan): Remove this copy when typed data pointers are
        // available for non-leaf calls.
        var buffer = arena<Uint8>(data.length);
        buffer.asTypedList(data.length).setAll(0, data);
        var remaining = data.length;

        // `write` on FreeBSD returns `EINVAL` if nbytes is greater than
        // `INT_MAX`.
        // See https://man.freebsd.org/cgi/man.cgi?write(2)
        final maxWriteSize =
            (io.Platform.isIOS || io.Platform.isMacOS) ? _maxInt32 : remaining;

        while (remaining > 0) {
          final w = _tempFailureRetry(
            () => write(fd, buffer, min(remaining, maxWriteSize)),
          );
          if (w == -1) {
            final errno = stdlibc.errno;
            throw _getError(errno, 'write failed', path);
          }
          remaining -= w;
          buffer += w;
        }
      });
    } finally {
      stdlibc.close(fd);
    }
  }
}
