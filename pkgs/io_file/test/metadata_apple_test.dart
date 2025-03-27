// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('ios || mac-os')
library;

import 'dart:io';

import 'package:io_file/src/vm_posix_file_system.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  final posixFileSystem = PosixFileSystem();

  group('windows metadata', () {
    late String tmp;

    setUp(() => tmp = createTemp('metadata'));

    tearDown(() => deleteTemp(tmp));

    group('isReadOnly', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = posixFileSystem.metadata(path);
      });
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = posixFileSystem.metadata('/Users/bquinlan/Library');
      });
    });
  });
}
