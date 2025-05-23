// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io';

import 'package:io_file/io_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'test_utils.dart';

void main() {
  group('createDirectory', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('createDirectory');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('success', () {
      final path = '$tmp/dir';

      fileSystem.createDirectory(path);
      expect(FileSystemEntity.isDirectorySync(path), isTrue);
    });

    test('absolute path, long directory name', () {
      // On Windows:
      // When using an API to create a directory, the specified path cannot be
      // so long that you cannot append an 8.3 file name (that is, the directory
      // name cannot exceed MAX_PATH minus 12).
      final dirname = ''.padLeft(
        Platform.isWindows ? win32.MAX_PATH - 12 : 255,
        'd',
      );
      final path = p.join(tmp, dirname);

      fileSystem.createDirectory(path);
      expect(FileSystemEntity.isDirectorySync(path), isTrue);
    });

    test('absolute path, too long directory name', () {
      final path = p.join(tmp, ''.padRight(256, 'd'));

      expect(
        () => fileSystem.createDirectory(path),
        throwsA(
          isA<FileSystemException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having((e) => e.path, 'path', path)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows
                    ? win32.ERROR_INVALID_NAME
                    : errors.enametoolong,
              ),
        ),
      );
    });

    test('relative path, long directory name', () {
      // On Windows:
      // When using an API to create a directory, the specified path cannot be
      // so long that you cannot append an 8.3 file name (that is, the directory
      // name cannot exceed MAX_PATH minus 12).
      final path = ''.padLeft(
        Platform.isWindows ? win32.MAX_PATH - 12 : 255,
        'd',
      );
      fileSystem.createDirectory(path);

      expect(FileSystemEntity.isDirectorySync(path), isTrue);
    });

    test('relative path, too long directory name', () {
      final path = ''.padRight(256, 'd');

      expect(
        () => fileSystem.createDirectory(path),
        throwsA(
          isA<FileSystemException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having((e) => e.path, 'path', path)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows
                    ? win32.ERROR_INVALID_NAME
                    : errors.enametoolong,
              ),
        ),
      );
    });

    test('create in non-existent directory', () {
      final path = '$tmp/foo/dir';

      expect(
        () => fileSystem.createDirectory(path),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having((e) => e.path, 'path', path)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_PATH_NOT_FOUND : errors.enoent,
              ),
        ),
      );
    });

    test('create over existing directory', () {
      final path = '$tmp/dir';
      Directory(path).createSync();

      expect(
        () => fileSystem.createDirectory(path),
        throwsA(
          isA<PathExistsException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having((e) => e.path, 'path', path)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_ALREADY_EXISTS : errors.eexist,
              ),
        ),
      );
    });

    test('create "."', () {
      const path = '.';
      expect(
        () => fileSystem.createDirectory(path),
        throwsA(
          isA<PathExistsException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having((e) => e.path, 'path', path)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_ALREADY_EXISTS : errors.eexist,
              ),
        ),
      );
    });

    test('create ".."', () {
      const path = '..';
      expect(
        () => fileSystem.createDirectory(path),
        throwsA(
          isA<PathExistsException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having((e) => e.path, 'path', path)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_ALREADY_EXISTS : errors.eexist,
              ),
        ),
      );
    });

    test('create over existing file', () {
      final path = '$tmp/file';
      File(path).createSync();

      expect(
        () => fileSystem.createDirectory(path),
        throwsA(
          isA<PathExistsException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having((e) => e.path, 'path', path)
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_ALREADY_EXISTS : errors.eexist,
              ),
        ),
      );
    });
  });
}
