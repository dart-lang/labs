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
  group('createDirectory', () {
    late String tmp;

    setUp(() => tmp = createTemp('createDirectory'));

    tearDown(() => deleteTemp(tmp));

    //TODO(brianquinlan): test with a very long path.

    test('success', () {
      final path = '$tmp/dir';

      fileSystem.createDirectory(path);
      expect(FileSystemEntity.isDirectorySync(path), isTrue);
    });

    test('create in non-existent directory', () {
      final path = '$tmp/foo/dir';

      expect(
        () => fileSystem.createDirectory(path),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows
                    ? win32.ERROR_FILE_NOT_FOUND
                    : stdlibc.ENOENT,
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
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows
                    ? win32.ERROR_ALREADY_EXISTS
                    : stdlibc.EEXIST,
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
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows
                    ? win32.ERROR_ALREADY_EXISTS
                    : stdlibc.EEXIST,
              ),
        ),
      );
    });
  });
}
