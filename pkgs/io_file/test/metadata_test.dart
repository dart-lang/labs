// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io';

import 'package:io_file/io_file.dart';
import 'package:io_file/src/vm_windows_file_system.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('metadata', () {
    late String tmp;

    setUp(() => tmp = createTemp('move'));

    tearDown(() => deleteTemp(tmp));

    //TODO(brianquinlan): test with a very long path.

    test('move file absolute path', () {
      final path = '$tmp/file1';

      File(path).writeAsStringSync('Hello World');

      final data = fileSystem.metadata(path) as WindowsMetadata;
      expect(data.isFile, isTrue);
      expect(data.lastAccessTime, DateTime.now().toUtc());
    });
  });
}
