// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

String createTemp(String testName) =>
    Directory.systemTemp.createTempSync(testName).absolute.path;
void deleteTemp(String path) => Directory(path).deleteSync(recursive: true);

String createLongPath(String inDir) {
  final path = p.join(
    inDir,
    ''.padLeft(255, 'a'),
    ''.padLeft(255, 'b'),
    ''.padLeft(255, 'c'),
  );
  Directory(path).createSync(recursive: true);
  return path;
}

Uint8List randomUint8List(int length, {int? seed}) {
  final random = Random(seed);
  final l = Uint8List(length);
  for (var i = 0; i < length; ++i) {
    l[i] = random.nextInt(255);
  }
  return l;
}
