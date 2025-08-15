// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'file_system.dart';

/// A [FileSystem] implementation for POSIX systems (e.g. Android, iOS, Linux,
/// macOS).
final class PosixFileSystem extends FileSystem {
  @override
  void copyFile(String oldPath, String newPath) {
    throw UnimplementedError();
  }

  @override
  void createDirectory(String path) {
    throw UnimplementedError();
  }

  @override
  String createTemporaryDirectory({String? parent, String? prefix}) {
    throw UnimplementedError();
  }

  @override
  String get currentDirectory {
    throw UnimplementedError();
  }

  @override
  set currentDirectory(String path) {
    throw UnimplementedError();
  }

  @override
  bool exists(String path) {
    throw UnimplementedError();
  }

  @override
  Metadata metadata(String path) {
    throw UnimplementedError();
  }

  @override
  Uint8List readAsBytes(String path) {
    throw UnimplementedError();
  }

  @override
  void removeDirectory(String path) {
    throw UnimplementedError();
  }

  @override
  void removeDirectoryTree(String path) {
    throw UnimplementedError();
  }

  @override
  void removeFile(String path) {
    throw UnimplementedError();
  }

  @override
  void rename(String oldPath, String newPath) {
    throw UnimplementedError();
  }

  @override
  bool same(String path1, String path2) {
    throw UnimplementedError();
  }

  @override
  void writeAsBytes(
    String path,
    Uint8List data, [
    WriteMode mode = WriteMode.failExisting,
  ]) {
    throw UnimplementedError();
  }

  @override
  void writeAsString(
    String path,
    String contents, [
    WriteMode mode = WriteMode.failExisting,
    Encoding encoding = utf8,
    String? lineTerminator,
  ]) {
    throw UnimplementedError();
  }
}
