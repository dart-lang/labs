// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

export 'file_system_file_utils.dart'
    if (dart.library.io) 'dart_io_file_utils.dart'
    show fileUtils;

String createTemp(String testName) =>
    Directory.systemTemp.createTempSync(testName).absolute.path;
void deleteTemp(String path) => Directory(path).deleteSync(recursive: true);

Uint8List randomUint8List(int length, {int? seed}) {
  final random = Random(seed);
  final l = Uint8List(length);
  for (var i = 0; i < length; ++i) {
    l[i] = random.nextInt(255);
  }
  return l;
}

abstract interface class FileUtils {
  String createTestDirectory(String testName);
  void deleteDirectoryTree(String path);

  bool isDirectory(String path);

  void createDirectory(String path);

  void createTextFile(String path, String s);
}
