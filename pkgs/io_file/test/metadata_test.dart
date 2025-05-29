// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('windows')
library;

import 'dart:io';

import 'package:io_file/io_file.dart';
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'test_utils.dart';

void main() {
  group('metadata', () {
    late String tmp;

    setUp(() => tmp = createTemp('metadata'));

    tearDown(() => deleteTemp(tmp));

    //TODO(brianquinlan): test with a very long path.

    test('path does not exist', () {
      expect(
        () => fileSystem.metadata('$tmp/file1'),
        throwsA(
          isA<PathNotFoundException>().having(
            (e) => e.osError?.errorCode,
            'errorCode',
            Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
          ),
        ),
      );
    });

    group('isDirectory/isFile/isLink', () {
      test('directory', () {
        final data = fileSystem.metadata(tmp);
        expect(data.isDirectory, isTrue);
        expect(data.isFile, isFalse);
        expect(data.isLink, isFalse);
      });
      test('file', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = fileSystem.metadata(path);
        expect(data.isDirectory, isFalse);
        expect(data.isFile, isTrue);
        expect(data.isLink, isFalse);
      });
      test('file link', () {
        File('$tmp/file1').writeAsStringSync('Hello World');
        final path = '$tmp/link';
        Link(path).createSync('$tmp/file1');

        final data = fileSystem.metadata(path);
        expect(data.isDirectory, isFalse);
        expect(data.isFile, isFalse);
        expect(data.isLink, isTrue);
      });

      test('directory link', () {
        File('$tmp/file1').writeAsStringSync('Hello World');
        final path = '$tmp/link';
        Link(path).createSync('$tmp/dir');

        final data = fileSystem.metadata(path);
        expect(data.isDirectory, isFalse);
        expect(data.isFile, isFalse);
        expect(data.isLink, isTrue);
      });
    });

    group('size', () {
      test('empty file', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('');

        final data = fileSystem.metadata(path);
        expect(data.size, 0);
      });
      test('non-empty file', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World!');

        final data = fileSystem.metadata(path);
        expect(data.size, 12);
      });
    });
  });
}
