// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:io_file/io_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'test_utils.dart';

void main() {
  group('removeDirectory', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('removeDirectory');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('success', () {
      final path = '$tmp/dir';
      io.Directory(path).createSync();

      fileSystem.removeDirectory(path);

      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test('absolute path, long directory name', () {
      // On Windows:
      // When using an API to create a directory, the specified path cannot be
      // so long that you cannot append an 8.3 file name (that is, the directory
      // name cannot exceed MAX_PATH minus 12).
      final dirname = 'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
      final path = p.join(tmp, dirname);
      io.Directory(path).createSync();

      fileSystem.removeDirectory(path);
      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test('relative path, long directory name', () {
      // On Windows:
      // When using an API to create a directory, the specified path cannot be
      // so long that you cannot append an 8.3 file name (that is, the directory
      // name cannot exceed MAX_PATH minus 12).
      final path = 'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
      io.Directory(path).createSync();

      fileSystem.removeDirectory(path);
      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test('non-empty directory', () {
      final path = '$tmp/dir';
      io.Directory(path).createSync();
      io.File('$tmp/dir/file').writeAsStringSync('Hello World!');

      expect(
        () => fileSystem.removeDirectory(path),
        throwsA(
          isA<IOFileException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows
                ? win32.ERROR_DIR_NOT_EMPTY
                : errors.enotempty,
          ),
        ),
      );
    });

    test('non-existent directory', () {
      final path = '$tmp/foo/dir';

      expect(
        () => fileSystem.removeDirectory(path),
        throwsA(
          isA<PathNotFoundException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows ? win32.ERROR_PATH_NOT_FOUND : errors.enoent,
          ),
        ),
      );
    });

    test('file', () {
      final path = '$tmp/file';
      io.File(path).writeAsStringSync('Hello World!');

      expect(
        () => fileSystem.removeDirectory(path),
        throwsA(
          isA<IOFileException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows ? win32.ERROR_DIRECTORY : errors.enotdir,
          ),
        ),
      );
    });

    test('link', () {
      final dirPath = '$tmp/dir';
      final linkPath = '$tmp/link';
      io.Directory(dirPath).createSync();
      io.Link(linkPath).createSync(dirPath);

      if (io.Platform.isWindows) {
        fileSystem.removeDirectory(linkPath);
        expect(
          io.FileSystemEntity.typeSync(dirPath),
          io.FileSystemEntityType.directory,
        );
        expect(
          io.FileSystemEntity.typeSync(linkPath),
          io.FileSystemEntityType.notFound,
        );
      } else {
        expect(
          () => fileSystem.removeDirectory(linkPath),
          throwsA(
            isA<IOFileException>().having(
              (e) => e.errorCode,
              'errorCode',
              io.Platform.isWindows
                  ? win32.ERROR_PATH_NOT_FOUND
                  : errors.enotdir,
            ),
          ),
        );
      }
    });
  });
}
