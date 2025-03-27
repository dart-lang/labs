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
  final int size;

  ReadAsBytesBenchmark(super.name, this.size);

  @override
  void setup() {
    dir = Directory.systemTemp.createTempSync('bench');
    path = '${dir.path}/file';
    File(path).writeAsBytesSync(Uint8List(size));
  }

  @override
  void teardown() {
    dir.deleteSync(recursive: true);
  }
}

class IOFilesReadAsBytesBenchmark extends ReadAsBytesBenchmark {
  IOFilesReadAsBytesBenchmark(int size)
    : super('IOFilesReadAsBytesBenchmark($size)', size);

  static void main(int size) {
    IOFilesReadAsBytesBenchmark(size).report();
  }

  @override
  void run() {
    fileSystem.readAsBytes(path);
  }
}

class DartIOReadAsBytesBenchmark extends ReadAsBytesBenchmark {
  DartIOReadAsBytesBenchmark(int size)
    : super('DartIOReadAsBytesBenchmark($size)', size);

  static void main(int size) {
    DartIOReadAsBytesBenchmark(size).report();
  }

  @override
  void run() {
    File(path).readAsBytesSync();
  }
}

void main() {
  for (var size in [0, 1024, 64 * 1024, 1024 * 1024, 64 * 1024 * 1024]) {
    DartIOReadAsBytesBenchmark.main(size);
    IOFilesReadAsBytesBenchmark.main(size);
  }
}
