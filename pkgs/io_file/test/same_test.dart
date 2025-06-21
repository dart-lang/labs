// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io';

import 'package:io_file/io_file.dart';
import 'package:stdlibc/stdlibc.dart' as stdlibc;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'test_utils.dart';

void main() {
  group('same', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('same');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('path1 does not exist', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';
      File(path2).writeAsStringSync('Hello World');

      expect(
        () => fileSystem.same(path1, path2),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.path, 'path', path1)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
              ),
        ),
      );
    });

    test('path2 does not exist', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';
      File(path1).writeAsStringSync('Hello World');

      expect(
        () => fileSystem.same(path1, path2),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.path, 'path', path2)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
              ),
        ),
      );
    });

    test('path1 and path2 same, do not exist', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file1';

      expect(
        () => fileSystem.same(path1, path2),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.path, 'path', path1)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
              ),
        ),
      );
    });

    test('path1 is a broken symlink', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';
      Link(path1).createSync('$tmp/file3');
      File(path2).writeAsStringSync('Hello World');

      expect(
        () => fileSystem.same(path1, path2),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.path, 'path', path1)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
              ),
        ),
      );
    });

    test('path2 is a broken symlink', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';
      File(path1).writeAsStringSync('Hello World');
      Link(path2).createSync('$tmp/file3');

      expect(
        () => fileSystem.same(path1, path2),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.path, 'path', path2)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
              ),
        ),
      );
    });

    test('path1 and path2 same, broken symlinks', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file1';
      Link(path1).createSync('$tmp/file3');

      expect(
        () => fileSystem.same(path1, path2),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.path, 'path', path1)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
              ),
        ),
      );
    });

    test('different files, same content', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';
      File(path1).writeAsStringSync('Hello World');
      File(path2).writeAsStringSync('Hello World');

      expect(fileSystem.same(path1, path2), isFalse);
    });

    test('same file, absolute and relative paths', () {
      fileSystem.currentDirectory = tmp;
      final path1 = '$tmp/file1';
      const path2 = 'file1';
      File(path1).writeAsStringSync('Hello World');

      expect(fileSystem.same(path1, path2), isTrue);
    });

    test('file path1, symlink path2', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';
      File(path1).writeAsStringSync('Hello World');
      Link(path2).createSync(path1);

      expect(fileSystem.same(path1, path2), isTrue);
    });

    test('file symlink path1, symlink path2', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';
      File('$tmp/file3').writeAsStringSync('Hello World');
      Link(path1).createSync('$tmp/file3');
      Link(path2).createSync('$tmp/file3');

      expect(fileSystem.same(path1, path2), isTrue);
    });

    test('files through intermediate symlinks', () {
      Directory('$tmp/subdir').createSync();
      Link('$tmp/link-to-subdir').createSync('$tmp/subdir');
      final path1 = '$tmp/subdir/file1';
      final path2 = '$tmp/link-to-subdir/file1';
      File(path1).writeAsStringSync('Hello World');

      expect(fileSystem.same(path1, path2), isTrue);
    });

    test(
      'hard links to same file',
      () {
        final path1 = '$tmp/file1';
        final path2 = '$tmp/file2';
        File(path1).writeAsStringSync('Hello World');
        stdlibc.link(path1, path2);
        expect(fileSystem.same(path1, path2), isTrue);
      },
      skip: Platform.isWindows ? 'hard links not supported' : false,
    );

    test('different directories, same content', () {
      final path1 = '$tmp/dir1';
      final path2 = '$tmp/dir2';
      Directory(path1).createSync();
      Directory(path2).createSync();

      expect(fileSystem.same(path1, path2), isFalse);
    });

    test('same directory, absolute and relative paths', () {
      final path1 = '$tmp/dir1';
      const path2 = 'dir1';
      Directory(path1).createSync();

      expect(fileSystem.same(path1, path2), isTrue);
    });

    test('directory path1, symlink path2', () {
      final path1 = '$tmp/dir1';
      final path2 = '$tmp/dir2';
      Directory(path1).createSync();
      Link(path2).createSync(path1);

      expect(fileSystem.same(path1, path2), isTrue);
    });

    test('directory symlink path1, symlink path2', () {
      final path1 = '$tmp/dir1';
      final path2 = '$tmp/dir2';
      Directory('$tmp/dir3').createSync();
      Link(path1).createSync('$tmp/dir3');
      Link(path2).createSync('$tmp/dir3');

      expect(fileSystem.same(path1, path2), isTrue);
    });

    test('directories through intermediate symlinks', () {
      Directory('$tmp/subdir').createSync();
      Link('$tmp/link-to-subdir').createSync('$tmp/subdir');
      final path1 = '$tmp/subdir/dir1';
      final path2 = '$tmp/link-to-subdir/dir1';
      Directory(path1).createSync();

      expect(fileSystem.same(path1, path2), isTrue);
    });
  });
}
