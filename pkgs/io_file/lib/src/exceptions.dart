// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SystemCallError {
  final String systemCall;
  final int errorCode;
  final String message;

  const SystemCallError(this.systemCall, this.errorCode, this.message);
}

class IOFileException implements Exception {
  final String message;

  /// The file system path on which the error occurred.
  ///
  /// Can be `null` if the exception does not relate directly
  /// to a file system path.
  final String? path;

  /// The underlying OS error.
  ///
  /// Can be `null` if the exception is not raised due to an OS error.
  final SystemCallError? systemCall;

  const IOFileException(this.message, {this.path, this.systemCall});

  String _toStringHelper(String className) {
    final sb = StringBuffer('$className: $message');
    if (path != null) {
      sb.write(', path = "$path"');
    }
    if (systemCall != null) {
      sb.write(
        ' (${systemCall!.systemCall}: ${systemCall!.message}, '
        'errno=${systemCall!.errorCode} )',
      );
    }
    return sb.toString();
  }

  @override
  String toString() => _toStringHelper('IOFileException');
}

class PathAccessException extends IOFileException {
  const PathAccessException(super.message, {super.path, super.systemCall});

  @override
  String toString() => _toStringHelper('PathAccessException');
}

class PathExistsException extends IOFileException {
  const PathExistsException(super.message, {super.path, super.systemCall});

  @override
  String toString() => _toStringHelper('PathExistsException');
}

class PathNotFoundException extends IOFileException {
  const PathNotFoundException(super.message, {super.path, super.systemCall});

  @override
  String toString() => _toStringHelper('PathNotFoundException');
}
