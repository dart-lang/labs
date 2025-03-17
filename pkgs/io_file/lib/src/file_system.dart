// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Information about a directory, link, etc. stored in the [FileSystem].
base class Metadata {
  // TODO(brianquinlan): Document all public fields.
  final bool isFile;
  final bool isDirectory;
  final bool isLink;
  final int size;

  Metadata({
    this.isDirectory = false,
    this.isFile = false,
    this.isLink = false,
    this.size = 0,
  }) {
    final count = (isDirectory ? 1 : 0) + (isFile ? 1 : 0) + (isLink ? 1 : 0);
    if (count > 1) {
      // TODO(brianquinlan): Decide whether a path must be a a file, directory
      // or link and whether it can be more than one of these at once.
      // Rust requires that at most one of these is true. Python has no such
      // restriction.
      throw ArgumentError(
        'only one of isDirectory, isFile, or isLink must be true',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Metadata &&
      isDirectory == other.isDirectory &&
      isFile == other.isFile &&
      isLink == other.isLink &&
      size == other.size;

  @override
  int get hashCode => (isDirectory, isFile, isLink, size).hashCode;
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

  /// Returns metadata for the given path.
  ///
  /// If `path` represents a symbolic link then metadata for the link is
  /// returned.
  Metadata metadata(String path) {
    throw UnsupportedError('metadata');
  }
}
