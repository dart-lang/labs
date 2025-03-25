// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:io_file/io_file.dart';

class ReadAsBytesBenchmark extends BenchmarkBase {
  late Directory dir;
  late String path;

  ReadAsBytesBenchmark(super.name);

  @override
  void setup() {
    dir = Directory.systemTemp.createTempSync('bench');
    path = '${dir.path}/file';
    File(path).writeAsBytesSync(Uint8List(10 * 1024 * 1024));
  }

  @override
  void teardown() {
    dir.deleteSync(recursive: true);
  }
}

class IOFilesReadAsBytesBenchmark extends ReadAsBytesBenchmark {
  IOFilesReadAsBytesBenchmark() : super('IOFilesReadAsBytesBenchmark');

  static void main() {
    IOFilesReadAsBytesBenchmark().report();
  }

  @override
  void run() {
    fileSystem.readAsBytes(path);
  }
}

class DartIOReadAsBytesBenchmark extends ReadAsBytesBenchmark {
  DartIOReadAsBytesBenchmark() : super('DartIOReadAsBytesBenchmark');

  static void main() {
    DartIOReadAsBytesBenchmark().report();
  }

  @override
  void run() {
    File(path).readAsBytes();
  }
}

void main() {
  DartIOReadAsBytesBenchmark.main();
  IOFilesReadAsBytesBenchmark.main();
}
