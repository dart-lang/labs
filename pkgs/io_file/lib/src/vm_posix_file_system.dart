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
  do {
    result = f();
  } while (result == -1 && stdlibc.errno == stdlibc.EINTR);
  return result;
}

/// The POSIX `read` function.
///
/// See https://pubs.opengroup.org/onlinepubs/9699919799/functions/read.html
@Native<Int Function(Int, Pointer<Uint8>, Int)>(isLeaf: false)
external int read(int fd, Pointer<Uint8> buf, int count);

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
    final fd = stdlibc.open(path, flags: stdlibc.O_RDONLY | stdlibc.O_CLOEXEC);
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
    final buffer = ffi.malloc<Uint8>(length);
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
          ffi.malloc.free(buffer);
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
  }
}
