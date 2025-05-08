// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:io_file/io_file.dart';

class WriteAsBytesBenchmark extends BenchmarkBase {
  late Directory dir;
  late String path;
  final Uint8List data;

  WriteAsBytesBenchmark(super.name, int size) : data = Uint8List(size);

  @override
  void setup() {
    dir = Directory.systemTemp.createTempSync('bench');
    path = '${dir.path}/file';
  }

  @override
  void teardown() {
    dir.deleteSync(recursive: true);
  }
}

class IOFilesWriteAsBytesBenchmark extends WriteAsBytesBenchmark {
  IOFilesWriteAsBytesBenchmark(int size)
    : super('IOFilesWriteAsBytesBenchmark($size)', size);

  static void main(int size) {
    IOFilesWriteAsBytesBenchmark(size).report();
  }

  @override
  void run() {
    fileSystem.writeAsBytes(path, data, WriteMode.truncateExisting);
  }
}

class DartIOWriteAsBytesBenchmark extends WriteAsBytesBenchmark {
  DartIOWriteAsBytesBenchmark(int size)
    : super('DartIOWriteAsBytesBenchmark($size)', size);

  static void main(int size) {
    DartIOWriteAsBytesBenchmark(size).report();
  }

  @override
  void run() {
    File(path).writeAsBytesSync(data);
  }
}

void main() {
  for (var size in [0, 1024, 64 * 1024, 1024 * 1024, 64 * 1024 * 1024]) {
    DartIOWriteAsBytesBenchmark.main(size);
    IOFilesWriteAsBytesBenchmark.main(size);
  }
}
