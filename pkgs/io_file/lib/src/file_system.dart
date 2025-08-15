// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart' show sealed;

import 'exceptions.dart';

// TODO(brianquinlan): When we switch to using exception types outside of
// `dart:io` then change the doc strings to use reference syntax rather than
// code syntax e.g. `PathExistsException` => [PathExistsException].

/// The type of a file system object, such as a file or directory.
enum FileSystemType {
  /// A special block file (also called a block device).
  ///
  /// Only exists on POSIX systems.
  block,

  /// A file that represents a character device, such as a terminal or printer.
  character,

  /// A container for other file system objects.
  directory,

  /// A regular file.
  file,

  /// A symbolic link.
  link,

  /// A pipe, named pipe or FIFO.
  pipe,

  /// A unix domain socket.
  ///
  /// Only exists on POSIX systems.
  socket,

  /// The type of the file could not be determined.
  unknown,
}

/// Information about a directory, link, etc. stored in the [FileSystem].
abstract interface class Metadata {
  /// The type of the file system object.
  FileSystemType get type;

  /// Whether the file system object is a regular file.
  ///
  /// This will be `false` for some file system objects that can be read or
  /// written to, such as sockets, pipes, and character devices. The most
  /// reliable way to determine if a file system object can be read or written
  /// to is to attempt to open it.
  ///
  /// At most one of [isDirectory], [isFile], or [isLink] will be `true`.
  bool get isFile;

  /// Whether the file system object is a directory.
  ///
  /// At most one of [isDirectory], [isFile], or [isLink] will be `true`.
  bool get isDirectory;

  /// Whether the file system object is symbolic link.
  ///
  /// At most one of [isDirectory], [isFile], or [isLink] will be `true`.
  bool get isLink;

  /// Whether the file system object is visible to the user.
  ///
  /// This will be `null` if the operating system does not support file system
  /// visibility. It will always be `null` on Android and Linux.
  bool? get isHidden;

  /// The size of the file system object in bytes.
  ///
  /// The `size` presented for file system objects other than regular files is
  /// platform-specific.
  int get size;

  /// The time that the file system object was last accessed.
  ///
  /// Access time is updated when the object is read or modified.
  ///
  /// The resolution of the access time varies by platform and file system.
  /// For example, FAT has an access time resolution of one day and NTFS may
  /// delay updating the access time for up to one hour after the last access.
  DateTime get access;

  /// The time that the file system object was created.
  ///
  /// This will always be `null` on platforms that do not track file creation
  /// time. It will always be `null` on Android and Linux.
  ///
  /// The resolution of the creation time varies by platform and file system.
  /// For example, FAT has a creation time resolution of 10 millseconds.
  DateTime? get creation;

  /// The time that the file system object was last modified.
  ///
  /// The resolution of the modification time varies by platform and file
  /// system. For example, FAT has a modification time resolution of 2 seconds.
  DateTime get modification;
}

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
///
/// TODO(brianquinlan): Far now, this class is not meant to be implemented,
/// extended outside of this package. Clarify somewhere that people implementing
/// this class should reach out to me.
///
/// On Windows, paths refering to objects in the
/// [win32 device namespace](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file#win32-device-namespaces),
/// such as named pipes, physical disks, and serial comnmunications ports
/// (e.g. 'COM1'), must be prefixed with `r'\\.\'`. For example, `'NUL'` would
/// be refered to by the path `r'\\.\NUL'`.
@sealed
abstract class FileSystem {
  /// Copy the data from the file at `oldPath` to  a new file at `newPath`.
  ///
  /// If `oldPath` is a directory, then `copyFile` throws [IOFileException]. If
  /// `oldPath` is a symbolic link to a file, then the contents of the file are
  /// copied.
  ///
  /// If `newPath` identifies an existing file system object, then `copyFile`
  /// throws [IOFileException].
  ///
  /// The metadata associated with `oldPath` (such as permissions, visibility,
  /// and creation time) is not copied to `newPath`.
  ///
  /// This operation is not atomic; if `copyFile` throws then a partial copy of
  /// `oldPath` may exist at `newPath`.
  // DESIGN NOTES:
  //
  // Metadata preservation:
  // Preserving all metadata from `oldPath` is very difficult. Languages that
  // offer metadata preservation on copy (Python, Java) make no guarantees as to
  // what metadata is preserved. The most principled approach is to leave
  // metadata preservation up to the application.
  //
  // Existing `newPath`:
  // If `newPath` exists then Rust opens the existing file and truncates it.
  // This has the effect of preserving the metadata of the **destination file**.
  // Python first removes the file at `newPath`. Java fails by default if
  // `newPath` exists. The most principled approach is to fail if `newPath`
  // exists and let the application deal with it.
  void copyFile(String oldPath, String newPath);

  /// Create a directory at the given path.
  ///
  /// If the directory already exists, then `PathExistsException` is thrown.
  ///
  /// If the parent path does not exist, then `PathNotFoundException` is thrown.
  void createDirectory(String path);

  /// Creates a temporary directory and returns its path.
  ///
  /// If `parent` is specified, then the temporary directory is created inside
  /// that directory. If `parent` is not specified, then the temporary directory
  /// will be created inside the directory found in [temporaryDirectory]. If
  /// `parent` is the empty string, then the temporary directory will be created
  /// in the current working directory. If the parent directory does not exist,
  /// then `PathExistsException` is thrown.
  ///
  /// The temporary directory name is constructed by combining the parent
  /// directory path, `prefix` (or the empty string if it is not provided), and
  /// some random characters to make the temporary directory name unique. Some
  /// characters in `prefix` may be removed or replaced. If `prefix` contains
  /// any directory navigation characters then they will be used. For example,
  /// a `prefix` of `'../foo'` will create a sibling directory to the parent
  /// directory.
  ///
  /// ```dart
  /// import 'package:io_file/io_file.dart';
  ///
  /// void main() {
  ///   final tmp = fileSystem.createTemporaryDirectory(prefix: 'myproject');
  ///   fileSystem.writeAsString('$tmp/README.txt', 'Hello World!');
  /// }
  /// ```
  String createTemporaryDirectory({String? parent, String? prefix});

  /// The current
  /// [working directory](https://en.wikipedia.org/wiki/Working_directory) of
  /// the Dart process.
  ///
  /// Absolute or relative paths can be set but the retrieved path will always
  /// be absolute.
  ///
  /// Setting the value of this field will change the working directory for
  /// *all* isolates.
  ///
  /// On Windows, unless
  /// [long paths are enabled](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation),
  /// the maximum length of the [currentDirectory] path is 260 characters.
  String get currentDirectory;
  set currentDirectory(String path);

  /// Checks if a file system object exists for the given path.
  ///
  /// Returns `true` if a file, directory, or link exists at the given path,
  /// and `false` otherwise.
  ///
  /// If `path` is a symbolic link, `exists` returns `true` even if the link
  /// is broken (i.e. the target of the link does not exist).
  bool exists(String path);

  /// TODO(brianquinlan): Add an `exists` method that can determine if a file
  /// exists without mutating it on Windows (maybe using `FindFirstFile`?)

  /// Metadata for the file system object at [path].
  ///
  /// If `path` represents a symbolic link then metadata for the link is
  /// returned.
  ///
  /// On Windows, asking for the metadata for a named pipe may cause the server
  /// to close it.
  ///
  /// The most reliable way to determine if a file system object can be read or
  /// written to is to attempt to open it.
  Metadata metadata(String path);

  /// Deletes the directory at the given path.
  ///
  /// If `path` is a directory but the directory is not empty, then
  /// `FileSystemException` is thrown. Use [removeDirectoryTree] to delete
  /// non-empty directories.
  ///
  /// If `path` is not directory:
  ///
  /// - On Windows, if `path` is a symbolic link to a directory then the
  ///   symbolic link is deleted. Otherwise, a `FileSystemException` is thrown.
  /// - On POSIX, a `FileSystemException` is thrown.
  void removeDirectory(String path);

  /// Deletes the directory at the given path and its contents.
  ///
  /// If the directory (or its subdirectories) contains any symbolic links then
  /// those links are deleted but their targets are not.
  void removeDirectoryTree(String path);

  /// Deletes the file at the given path.
  ///
  /// If `path` represents a directory, then [IOFileException] is thrown.
  ///
  /// If `path` represents a symbolic link to a file, then the symbolic link is
  /// deleted.
  ///
  /// If `path` represents a symbolic link to a directory then, on POSIX, the
  /// symbolic link is deleted. On Windows, a [IOFileException] is thrown.
  void removeFile(String path);

  /// Reads the entire file contents as a list of bytes.
  Uint8List readAsBytes(String path);

  /// Renames, and possibly moves a file system object from one path to another.
  ///
  /// If `newPath` is a relative path, it is resolved against the current
  /// working directory. This means that simply changing the name of a file,
  /// but keeping it the original directory, requires creating a new complete
  /// path with the new name at the end.
  ///
  /// TODO(brianquinlan): add an example here.
  ///
  /// On some platforms, a rename operation cannot move a file between
  /// different file systems. If that is the case, instead copy the file to the
  /// new location and then remove the original.
  ///
  /// If `newPath` identifies an existing file or link, that entity is removed
  /// first. If `newPath` identifies an existing directory, the operation
  /// fails and raises [PathExistsException].
  void rename(String oldPath, String newPath);

  /// Checks whether two paths refer to the same object in the file system.
  ///
  /// Throws [PathNotFoundException] if either path doesn't exist.
  ///
  /// Links are resolved before determining if the paths refer to the same
  /// object. Throws [PathNotFoundException] if either path requires resolving
  /// a broken link.
  bool same(String path1, String path2);

  /// The directory path used to store temporary files.
  ///
  /// On Android, Linux, macOS and iOS, the path is taken from:
  /// 1. the TMPDIR environment variable if set
  /// 2. the TMP environment variable if set
  /// 3. '/data/local/tmp' on Android, '/tmp' elsewhere
  ///
  /// On Windows, the path is taken from:
  /// 1. the TMP environment variable if set
  /// 2. the TEMP environment variable if set
  /// 3. the USERPROFILE environment variable if set
  /// 4. the Windows directory
  String get temporaryDirectory {
    throw UnsupportedError('temporaryDirectory');
  }

  /// Write the given bytes to a file.
  ///
  /// If `path` is a broken symlink and `mode` is [WriteMode.failExisting]:
  /// - On Windows, the target of the symlink is created, using `data` as its
  ///   contents.
  /// - On POSIX, [writeAsBytes] throws [PathExistsException].
  void writeAsBytes(
    String path,
    Uint8List data, [
    WriteMode mode = WriteMode.failExisting,
  ]);

  /// Write the string to a file.
  ///
  /// If `path` is a broken symlink and `mode` is [WriteMode.failExisting]:
  /// - On Windows, the target of the symlink is created, using `data` as its
  ///   contents.
  /// - On POSIX, [writeAsBytes] throws [PathExistsException].
  ///
  /// `lineTerminator` is used to replace `'\n'` characters in `content`.
  /// If `lineTerminator` is provided, then it must be one of `'\n'` or
  /// `'\r\n'`. If `lineTerminator` is not provided then the platform line
  /// ending is used, i.e. `'\r\n'` on Windows and `'\n'` everwhere else.
  void writeAsString(
    String path,
    String contents, [
    WriteMode mode = WriteMode.failExisting,
    Encoding encoding = utf8,
    String? lineTerminator,
  ]);
}
