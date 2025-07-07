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

import 'test_utils.dart';

void main() {
  group('currentDirectory', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('currentDirectory');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('absolute path', () {
      final path = '$tmp/dir';
      io.Directory(path).createSync(recursive: true);

      fileSystem.currentDirectory = path;

      expect(
        fileSystem.same(fileSystem.currentDirectory, path),
        isTrue,
        reason:
            '${fileSystem.currentDirectory} is a diffent directory than'
            '$path',
      );
      expect(
        p.isAbsolute(fileSystem.currentDirectory),
        isTrue,
        reason: '${fileSystem.currentDirectory} is not absolute',
      );
    });

    test('absolute path, too long path', () {
      // On Windows, limited to MAX_PATH (260) characters.
      final path = p.join(tmp, 'a' * 200, 'b' * 200);
      io.Directory(path).createSync(recursive: true);
      final oldCurrentDirectory = fileSystem.currentDirectory;

      expect(
        () => fileSystem.currentDirectory = path,
        throwsA(
          isA<IOFileException>()
              .having((e) => e.path1, 'path1', path)
              .having(
                (e) => e.errorCode,
                'errorCode',
                win32.ERROR_FILENAME_EXCED_RANGE,
              ),
        ),
      );
      expect(fileSystem.currentDirectory, oldCurrentDirectory);
    }, skip: !io.Platform.isWindows);

    test('relative path', () {
      final path = '$tmp/dir';
      io.Directory(path).createSync(recursive: true);

      fileSystem.currentDirectory = 'dir';

      expect(
        fileSystem.same(fileSystem.currentDirectory, path),
        isTrue,
        reason:
            '${fileSystem.currentDirectory} is a diffent directory than '
            '$path',
      );
      expect(
        p.isAbsolute(fileSystem.currentDirectory),
        isTrue,
        reason: '${fileSystem.currentDirectory} is not absolute',
      );
    });
  });
}
