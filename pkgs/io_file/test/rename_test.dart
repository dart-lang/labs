// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('posix')
library;

import 'dart:io';
import 'package:io_file/posix_file_system.dart';
import 'package:test/test.dart';

void main() {
  group('move', () {
    late String tmp;

    setUp(
      () => tmp = Directory.systemTemp.createTempSync('move').absolute.path,
    );

    tearDown(() => Directory(tmp).deleteSync(recursive: true));

    // TODO: test with a very long path.

    test('move file absolute path', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      File(path1).writeAsStringSync('Hello World');
      PosixFileSystem().rename(path1, path2);
      expect(File(path1).existsSync(), isFalse);
      expect(File(path2).existsSync(), isTrue);
    });

    test('move file to existing', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      File(path1).writeAsStringSync('Hello World #1');
      File(path2).writeAsStringSync('Hello World #2');
      PosixFileSystem().rename(path1, path2);
      expect(File(path1).existsSync(), isFalse);
      expect(File(path2).readAsStringSync(), 'Hello World #1');
    });

    test('move directory absolute path', () {
      final path1 = '$tmp/dir1';
      final path2 = '$tmp/dir2';

      Directory(path1).createSync(recursive: true);
      PosixFileSystem().rename(path1, path2);
      expect(Directory(path1).existsSync(), isFalse);
      expect(Directory(path2).existsSync(), isTrue);
    });

    test('move non-existant', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      expect(
        () => PosixFileSystem().rename(path1, path2),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.message, 'message', 'rename failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                2, // ENOENT
              ),
        ),
      );
    });

    test('move to existant directory', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/dir1';

      File(path1).writeAsStringSync('Hello World');
      Directory(path2).createSync(recursive: true);

      expect(
        () => PosixFileSystem().rename(path1, path2),
        throwsA(
          isA<FileSystemException>()
              .having((e) => e.message, 'message', 'rename failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                21, // EISDIR
              ),
        ),
      );
    });
  });
}
