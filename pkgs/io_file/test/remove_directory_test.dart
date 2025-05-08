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

import 'test_utils.dart';

void main() {
  group('removeDirectory', () {
    late String tmp;

    setUp(() => tmp = createTemp('removeDirectory'));

    tearDown(() => deleteTemp(tmp));

    //TODO(brianquinlan): test with a very long path.

    test('success', () {
      final path = '$tmp/dir';
      Directory(path).createSync();

      fileSystem.removeDirectory(path);

      expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound);
    });

    test('non-empty directory', () {
      final path = '$tmp/dir';
      Directory(path).createSync();
      File('$tmp/dir/file').writeAsStringSync('Hello World!');

      expect(
        () => fileSystem.removeDirectory(path),
        throwsA(
          isA<FileSystemException>()
              .having((e) => e.message, 'message', 'remove directory failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows
                    ? win32.ERROR_DIR_NOT_EMPTY
                    : stdlibc.ENOTEMPTY,
              ),
        ),
      );
    });

    test('non-existent directory', () {
      final path = '$tmp/foo/dir';

      expect(
        () => fileSystem.removeDirectory(path),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.message, 'message', 'remove directory failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows
                    ? win32.ERROR_PATH_NOT_FOUND
                    : stdlibc.ENOENT,
              ),
        ),
      );
    });

    test('file', () {
      final path = '$tmp/file';
      File(path).writeAsStringSync('Hello World!');

      expect(
        () => fileSystem.removeDirectory(path),
        throwsA(
          isA<FileSystemException>()
              .having((e) => e.message, 'message', 'remove directory failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_DIRECTORY : stdlibc.ENOTDIR,
              ),
        ),
      );
    });

    test('link', () {
      final dirPath = '$tmp/dir';
      final linkPath = '$tmp/link';
      Directory(dirPath).createSync();
      Link(linkPath).createSync(dirPath);

      if (Platform.isWindows) {
        fileSystem.removeDirectory(linkPath);
        expect(
          FileSystemEntity.typeSync(dirPath),
          FileSystemEntityType.directory,
        );
        expect(
          FileSystemEntity.typeSync(linkPath),
          FileSystemEntityType.notFound,
        );
      } else {
        expect(
          () => fileSystem.removeDirectory(linkPath),
          throwsA(
            isA<FileSystemException>()
                .having((e) => e.message, 'message', 'remove directory failed')
                .having(
                  (e) => e.osError?.errorCode,
                  'errorCode',
                  Platform.isWindows
                      ? win32.ERROR_PATH_NOT_FOUND
                      : stdlibc.ENOTDIR,
                ),
          ),
        );
      }
    });
  });
}
