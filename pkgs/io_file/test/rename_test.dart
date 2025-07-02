// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:io_file/io_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('rename', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('rename');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('move file absolute path', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      io.File(path1).writeAsStringSync('Hello World');
      fileSystem.rename(path1, path2);
      expect(io.File(path1).existsSync(), isFalse);
      expect(io.File(path2).existsSync(), isTrue);
    });

    test('move between absolute paths, long file names', () {
      final path1 = p.join(tmp, '1' * 255);
      final path2 = p.join(tmp, '2' * 255);
      io.File(path1).writeAsStringSync('Hello World');

      fileSystem.rename(path1, path2);
      expect(io.File(path1).existsSync(), isFalse);
      expect(io.File(path2).existsSync(), isTrue);
    });

    test('move between relative path, long file names', () {
      final path1 = '1' * 255;
      final path2 = '2' * 255;
      io.File(path1).writeAsStringSync('Hello World');

      fileSystem.rename(path1, path2);
      expect(io.File(path1).existsSync(), isFalse);
      expect(io.File(path2).existsSync(), isTrue);
    });

    test('move file to existing', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      io.File(path1).writeAsStringSync('Hello World #1');
      io.File(path2).writeAsStringSync('Hello World #2');
      fileSystem.rename(path1, path2);
      expect(io.File(path1).existsSync(), isFalse);
      expect(io.File(path2).readAsStringSync(), 'Hello World #1');
    });

    test('move directory absolute path', () {
      final path1 = '$tmp/dir1';
      final path2 = '$tmp/dir2';

      io.Directory(path1).createSync(recursive: true);
      fileSystem.rename(path1, path2);
      expect(io.Directory(path1).existsSync(), isFalse);
      expect(io.Directory(path2).existsSync(), isTrue);
    });

    test('move non-existant', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      expect(
        () => fileSystem.rename(path1, path2),
        throwsA(
          isA<PathNotFoundException>().having(
            (e) => e.errorCode,
            'errorCode',
            2, // ENOENT, ERROR_FILE_NOT_FOUND
          ),
        ),
      );
    });

    test('move to existant directory', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/dir1';

      io.File(path1).writeAsStringSync('Hello World');
      io.Directory(path2).createSync(recursive: true);

      expect(
        () => fileSystem.rename(path1, path2),
        throwsA(
          isA<IOFileException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows
                ? 5 // ERROR_ACCESS_DENIED
                : 21, // EISDIR
          ),
        ),
      );
    });
  });
}
