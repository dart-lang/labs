// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('windows')
library;

import 'dart:io';

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

    group('isHidden', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isHidden, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isHidden: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isHidden, isTrue);
      });
    });

    group('isSystem', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isSystem, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isSystem: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isSystem, isTrue);
      });
    });

    group('isArchive', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isArchive: false);

        final data = windowsFileSystem.metadata(path);
        expect(data.isArchive, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isArchive: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isArchive, isTrue);
      });
    });

    group('isTemporary', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isTemporary, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isTemporary: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isTemporary, isTrue);
      });
    });

    group('isContentNotIndexed', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isContentNotIndexed, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isContentNotIndexed: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isContentNotIndexed, isTrue);
      });
    });

    group('isOffline', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isOffline, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isOffline: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isOffline, isTrue);
      });
    });
  });
}
