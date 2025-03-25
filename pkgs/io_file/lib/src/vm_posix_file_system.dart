// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:stdlibc/stdlibc.dart' as stdlibc;
import 'package:meta/meta.dart';

import 'file_system.dart';

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

int _tempFailureRetry(int Function() f) {
  int result;
  do {
    result = f();
  } while (result == -1 && stdlibc.errno == stdlibc.EINTR);
  return result;
}

// The maximum number of bytes to read in a single call to `read`.
//
// On macOS, it is an error to call
// `read/_read(fildes, buf, nbyte)` with `nbyte >= INT_MAX`.
//
// The POSIX specification states that the behavior of `read` is
// implementation-defined if `nbyte > SSIZE_MAX`. On Linux, the `read` will
// transfer at most 0x7ffff000 bytes and return the number of bytes actually.
// transfered.
//
// A smaller value has the advantage of making vm-service clients
// (e.g. debugger) more responsive.
//
// A bigger value reduces the number of system calls.
@visibleForTesting
const int maxReadSize = 16 * 1024 * 1024; // 16MB.

// If the size of a file is unknown, read in blocks of this size.
@visibleForTesting
const int blockSize = 64 * 1024;

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
      if (stat != null &&
          stat.st_size == 0 &&
          stat.st_mode & stdlibc.S_IFREG != 0) {
        return Uint8List(0);
      }
      final length = stat?.st_size ?? 0;
      if (length == 0) {
        return _readNoLength(path, fd);
      } else {
        return _readLength(path, fd, length);
      }
    } finally {
      stdlibc.close(fd);
    }
  }

  Uint8List _readNoLength(String path, int fd) => ffi.using((arena) {
    final buf = ffi.malloc<Uint8>(blockSize);
    final builder = BytesBuilder(copy: true);

    while (true) {
      final r = _tempFailureRetry(() => read(fd, buf, blockSize));
      switch (r) {
        case -1:
          final errno = stdlibc.errno;
          throw _getError(errno, 'read failed', path);
        case 0:
          return builder.takeBytes();
        default:
          final typed = buf.asTypedList(r);
          builder.add(typed);
      }
    }
  });

  Uint8List _readLength(String path, int fd, int length) {
    final buf = ffi.malloc<Uint8>(length);
    var offset = 0;

    while (offset < length) {
      final r = _tempFailureRetry(
        () =>
            read(fd, (buf + offset).cast(), min(length - offset, maxReadSize)),
      );
      switch (r) {
        case -1:
          final errno = stdlibc.errno;
          ffi.calloc.free(buf);
          throw _getError(errno, 'read failed', path);
        case 0:
          return buf.asTypedList(offset, finalizer: ffi.calloc.nativeFree);
        default:
          offset += r;
      }
    }
    return buf.asTypedList(length, finalizer: ffi.calloc.nativeFree);
  }
}
