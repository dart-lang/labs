// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('windows')
library;

import 'dart:io';

import 'package:io_file/io_file.dart';
import 'package:io_file/src/vm_windows_file_system.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  final windowsFileSystem = WindowsFileSystem();

  group('metadata', () {
    late String tmp;

    setUp(() => tmp = createTemp('metadata'));

    tearDown(() => deleteTemp(tmp));

    //TODO(brianquinlan): test with a very long path.

    group('isReadOnly', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isReadOnly, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isReadOnly: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isReadOnly, isTrue);
      });
    });
  });
}
