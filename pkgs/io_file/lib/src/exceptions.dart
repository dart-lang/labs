// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'file_system.dart';

// Design Notes:
//
// The [IOFileException] hierarchy is roughly based on the Java
// `FileSystemException` hierarchy and the Python `OSError` hierarchy.
//
// There is no exception corresponding to the POSIX `EISDIR` error code because
// there is no corresponding Windows error code.

/// Exception thrown when a file operation fails.
class IOFileException implements Exception {
  // A description of the failed operation, such as
  //`'No such file or directory'`.
  final String message;

  /// The operating-system defined code for the error, such as 2 for
  /// `ERROR_FILE_NOT_FOUND` on Windows.
  final int? errorCode;

  /// A path provided in a failed file operation.
  ///
  /// For file operations that involve a single path
  /// (e.g. [FileSystem.readAsBytes]), `path1` will be the provided path.
  ///
  /// For file operations that involve two paths (e.g. [FileSystem.rename]),
  /// `path1` will be the first path argument.
  ///
  /// Will be `null` for file operations that do not specify a path.
  final String? path1;

  /// A path provided in a failed file operation.
  ///
  /// For file operations that involve a single path
  /// (e.g. [FileSystem.readAsBytes]), [path1] will be set and `path2` will be
  /// `null`.
  ///
  /// For file operations that involve two paths (e.g. [FileSystem.rename]),
  /// `path2` will be the second path argument.
  ///
  /// Will be `null` for file operations that do not specify a path.
  final String? path2;

  /// The underlying system call that failed.
  ///
  /// Can be `null` if the exception is not raised due to a failed system call.
  final String? systemCall;

  const IOFileException(
    this.message, {
    this.path1,
    this.path2,
    this.systemCall,
    this.errorCode,
  });

  String _toStringHelper(String className) {
    final sb = StringBuffer('$className: $message');
    // IOFileException: No such file or directory
    if (path1 != null) {
      // IOFileException: No such file or directory: "a"
      sb.write(': "$path1"');
    }
    if (path2 != null) {
      // IOFileException: No such file or directory: "a" -> "b"
      sb.write(' -> "$path2"');
    }
    sb.write(switch ((systemCall, errorCode)) {
      // ... or directory: "a" -> "b"
      (null, null) => '',
      // ... or directory: "a" -> "b" [errorCode: 2]
      (null, final error?) => ' [errorCode: $error]',
      // ... or directory: "a" -> "b" [renameat failed]
      (final call?, null) => ' [$call failed]',
      // ... or directory: "a" -> "b" [renameat failed with errorCode: 2]
      (final error?, final call?) => ' [$error failed with errorCode: $call]',
    });
    return sb.toString();
  }

  @override
  String toString() => _toStringHelper('IOFileException');
}

/// Exception thrown when a file operation that only works on empty directories
/// (such as [FileSystem.removeDirectory]) is requested on directory that is not
/// empty.
///
/// This exception corresponds to errors such as `ENOTEMPTY` on POSIX systems
/// and `ERROR_DIR_NOT_EMPTY` on Windows.
class DirectoryNotEmptyException extends IOFileException {
  const DirectoryNotEmptyException(
    super.message, {
    super.path1,
    super.path2,
    super.systemCall,
    super.errorCode,
  });

  @override
  String toString() => _toStringHelper('DirectoryNotEmptyException');
}

/// Exception thrown when a file operation (such as
/// [FileSystem.writeAsString]) is requested on there is not enough available
/// disk.
///
/// This exception corresponds to errors such as `ENOSPC` on POSIX systems and
/// `ERROR_DISK_FULL` on Windows.
class DiskFullException extends IOFileException {
  const DiskFullException(
    super.message, {
    super.path1,
    super.path2,
    super.systemCall,
    super.errorCode,
  });

  @override
  String toString() => _toStringHelper('DiskFullException');
}

/// Exception thrown when a directory operation (such as
/// [FileSystem.removeDirectory]) is requested on a non-directory.
///
/// This exception corresponds to error codes such as `ENOTDIR` on POSIX systems
/// and `ERROR_DIRECTORY` on Windows.
class NotADirectoryException extends IOFileException {
  const NotADirectoryException(
    super.message, {
    super.path1,
    super.path2,
    super.systemCall,
    super.errorCode,
  });

  @override
  String toString() => _toStringHelper('NotADirectoryException');
}

/// Exception thrown when a file operation fails because the necessary access
/// rights are not available.
///
/// This exception corresponds to error codes such as `EACCES` on POSIX systems
/// and `ERROR_ACCESS_DENIED` on Windows.
class PathAccessException extends IOFileException {
  const PathAccessException(
    super.message, {
    super.path1,
    super.path2,
    super.systemCall,
    super.errorCode,
  });

  @override
  String toString() => _toStringHelper('PathAccessException');
}

/// Exception thrown when a file operation fails because the target path already
/// exists.
///
/// This exception corresponds to error codes such as `EEXIST` on POSIX systems
/// and `ERROR_ALREADY_EXISTS` on Windows.
class PathExistsException extends IOFileException {
  const PathExistsException(
    super.message, {
    super.path1,
    super.path2,
    super.systemCall,
    super.errorCode,
  });

  @override
  String toString() => _toStringHelper('PathExistsException');
}

/// Exception thrown when a file operation fails because the referenced file
/// system object or objects do not exist.
///
/// This exception corresponds to error codes such as `ENOENT` on POSIX systems
/// and `ERROR_FILE_NOT_FOUND` on Windows.
class PathNotFoundException extends IOFileException {
  const PathNotFoundException(
    super.message, {
    super.path1,
    super.path2,
    super.systemCall,
    super.errorCode,
  });

  @override
  String toString() => _toStringHelper('PathNotFoundException');
}

/// Exception thrown when there are too many open files.
///
/// This exception corresponds to error codes such as `EMFILE` on POSIX systems
/// and `ERROR_TOO_MANY_OPEN_FILES` on Windows.
class TooManyOpenFilesException extends IOFileException {
  const TooManyOpenFilesException(
    super.message, {
    super.path1,
    super.path2,
    super.systemCall,
    super.errorCode,
  });

  @override
  String toString() => _toStringHelper('TooManyOpenFilesException');
}
