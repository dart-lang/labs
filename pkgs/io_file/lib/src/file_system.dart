// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

class WriteMode {
  static const appendExisting = WriteMode._(1);
  static const truncateExisting = WriteMode._(2);
  static const failExisting = WriteMode._(3);

  final int _mode;
  const WriteMode._(this._mode);

  @override
  bool operator ==(Object other) => other is WriteMode && _mode == other._mode;

  @override
  int get hashCode => _mode.hashCode;
}

/// An abstract representation of a file system.
base class FileSystem {
  /// Renames, and possibly moves a file system object from one path to another.
  ///
  /// If `newPath` is a relative path, it is resolved against the current
  /// working directory. This means that simply changing the name of a file,
  /// but keeping it the original directory, requires creating a new complete
  /// path with the new name at the end.
  ///
  ///TODO(brianquinlan): add an example here.
  ///
  /// On some platforms, a rename operation cannot move a file between
  /// different file systems. If that is the case, instead copy the file to the
  /// new location and then remove the original.
  ///
  // If `newPath` identifies an existing file or link, that entity is removed
  // first. If `newPath` identifies an existing directory, the operation
  // fails and raises [PathExistsException].
  void rename(String oldPath, String newPath) {
    throw UnsupportedError('rename');
  }

  /// Reads the entire file contents as a list of bytes.
  Uint8List readAsBytes(String path) {
    throw UnsupportedError('readAsBytes');
  }

  /// Write the given bytes to a file.
  void writeAsBytes(
    String path,
    Uint8List data, [
    WriteMode mode = WriteMode.failExisting,
  ]) {
    throw UnsupportedError('writeAsBytes');
  }
}
