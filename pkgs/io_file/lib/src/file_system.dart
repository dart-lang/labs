// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

// TODO(brianquinlan): When we switch to using exception types outside of
// `dart:io` then change the doc strings to use reference syntax rather than
// code syntax e.g. `PathExistsException` => [PathExistsException].

/// The modes in which a File can be written.
class WriteMode {
  /// Open the file for writing such that data can only be appended to the end
  /// of it. The file is created if it does not already exist.
  static const appendExisting = WriteMode._(1);

  /// Open the file for writing and discard any existing data in the file.
  /// The file is created if it does not already exist.
  static const truncateExisting = WriteMode._(2);

  /// Open the file for writing and file with a `PathExistsException` if the
  /// file already exists.
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
  /// Checks whether two paths refer to the same object in the file system.
  ///
  /// Throws `PathNotFoundException` if either path doesn't exist.
  ///
  /// Links are resolved before determining if the paths refer to the same
  /// object. Throws `PathNotFoundException` if either path requires resolving
  /// a broken link.
  bool same(String path1, String path2) {
    throw UnsupportedError('same');
  }

  /// Create a directory at the given path.
  ///
  /// If the directory already exists, then `PathExistsException` is thrown.
  ///
  /// If the parent path does not exist, then `PathNotFoundException` is thrown.
  void createDirectory(String path) {
    throw UnsupportedError('createDirectory');
  }

  /// Deletes the directory at the given path.
  ///
  /// If `path` is a directory but the directory is not empty, then
  /// `FileSystemException` is thrown.
  ///
  /// TODO(bquinlan): Explain how to delete non-empty directories.
  ///
  /// If `path` is not directory:
  ///
  /// - On Windows, if `path` is a symbolic link to a directory then the
  ///   symbolic link is deleted. Otherwise, a `FileSystemException` is thrown.
  /// - On POSIX, a `FileSystemException` is thrown.
  void removeDirectory(String path) {
    throw UnsupportedError('removeDirectory');
  }

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
  ///
  /// If `path` is a broken symlink and `mode` is [WriteMode.failExisting]:
  ///
  /// - On Windows, the target of the symlink is created, using `data` as its
  ///   contents.
  /// - On POSIX, [writeAsBytes] throws `PathExistsException`.
  void writeAsBytes(
    String path,
    Uint8List data, [
    WriteMode mode = WriteMode.failExisting,
  ]) {
    throw UnsupportedError('writeAsBytes');
  }
}
