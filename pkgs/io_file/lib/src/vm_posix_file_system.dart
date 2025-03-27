// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:meta/meta.dart';
import 'package:stdlibc/stdlibc.dart' as stdlibc;

import 'file_system.dart';

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

final class PosixMetadata {
  @override
  final bool isDirectory;

  @override
  final bool isFile;

  @override
  final bool isLink;

  @override
  final int size;

  @override
  final bool isHidden;

  PosixMetadata({
    this.isDirectory = false,
    this.isFile = false,
    this.isLink = false,

    this.size = 0,

    this.isHidden = false,
  });
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
      if (stat != null &&
          stat.st_size == 0 &&
          stat.st_mode & stdlibc.S_IFREG != 0) {
        return Uint8List(0);
      }
      final length = stat?.st_size ?? 0;
      if (length == 0) {
        return _readUnknownLength(path, fd);
      } else {
        return _readKnownLength(path, fd, length);
      }
    } finally {
      stdlibc.close(fd);
    }
  }

  Uint8List _readUnknownLength(String path, int fd) => ffi.using((arena) {
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
          ffi.calloc.free(buffer);
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

  Object metadata(String path) {
    final stat = stdlibc.stat(path);
    if (stat == null) {
      final errno = stdlibc.errno;
      throw _getError(errno, 'stat failed', path);
    }

    if (io.Platform.isIOS || io.Platform.isMacOS) {
      final flags = stat.st_flags!;
      if (flags & stdlibc.UF_HIDDEN != 0) {
        print('Hidden');
      } else {
        print('Not hidden');
      }
    }
    
    stat.st_mode;
    return PosixMetadata(isDirectory: stat.st_mode & stdlibc.S_IFDIR != 0,
    isFile: ,
    isLink: stat.st_mode & stdlibc.S_IFLNK != 0,
    size: stat.st_size);
  }
}
