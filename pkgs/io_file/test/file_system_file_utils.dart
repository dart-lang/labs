// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:io_file/io_file.dart';

import 'test_utils.dart';

/// File utilities implemented using [FileSystem].
///
/// Used to verify the behavior of mocks and other implementations that may not
/// touch the platform file system.
class FileSystemFileUtils implements FileUtils {
  final FileSystem fs;

  FileSystemFileUtils([FileSystem? fs]) : fs = fs ?? fileSystem;

  @override
  void createBinaryFile(String path, Uint8List b) => fs.writeAsBytes(path, b);

  @override
  void createDirectory(String path) {
    fs.createDirectory(path);
  }

  @override
  void deleteDirectory(String path) {
    // TODO: implement deleteDirectory
  }

  @override
  String createTestDirectory(String testName) =>
      fs.createTemporaryDirectory(prefix: testName);

  @override
  void createTextFile(String path, String s) {
    fs.writeAsString(path, s);
  }

  @override
  void deleteDirectoryTree(String path) {
    fs.removeDirectoryTree(path);
  }

  @override
  bool exists(String path) {
    // TODO(brianquinlan): Switch to `FileSystem.exists` when such a method
    // exists.
    try {
      fs.metadata(path);
    } on PathNotFoundException {
      return false;
    }
    return true;
  }

  @override
  bool isDirectory(String path) => fs.metadata(path).isDirectory;

  @override
  Uint8List readBinaryFile(String path) => fs.readAsBytes(path);
}

FileUtils fileUtils() => FileSystemFileUtils();
