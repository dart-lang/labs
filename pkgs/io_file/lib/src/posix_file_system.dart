// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:stdlibc/stdlibc.dart' as stdlibc;

import 'file_system.dart';

Exception _getError(int errno, String message, String path) {
  // TODO: In the long-term, do we need to avoid exceptions that are part of
  // `dart:io`? Can we move those exceptions into a different namespace?
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
}
