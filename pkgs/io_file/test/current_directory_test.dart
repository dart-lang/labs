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
  group('currentDirectory', () {
    late String tmp;

    setUp(() => tmp = createTemp('currentDirectory'));

    tearDown(() => deleteTemp(tmp));

    //TODO(brianquinlan): test with a very long path.

    test('absolute path', () {
      final path = '$tmp/dir';
      Directory(path).createSync(recursive: true);
      final oldCurrentDirectory = fileSystem.currentDirectory;

      try {
        fileSystem.currentDirectory = path;
        expect(
          fileSystem.same(fileSystem.currentDirectory, path),
          isTrue,
          reason:
              '${fileSystem.currentDirectory} is a diffent directory than $path',
        );
      } finally {
        fileSystem.currentDirectory = oldCurrentDirectory;
      }
    });

    test('relative path', () {
      final path = '$tmp/dir';
      Directory(path).createSync(recursive: true);
      final oldCurrentDirectory = fileSystem.currentDirectory;

      try {
        fileSystem.currentDirectory = tmp;

        fileSystem.currentDirectory = 'dir';
        print(fileSystem.currentDirectory);
        expect(
          fileSystem.same(fileSystem.currentDirectory, path),
          isTrue,
          reason:
              '${fileSystem.currentDirectory} is a diffent directory than $path',
        );
      } finally {
        fileSystem.currentDirectory = oldCurrentDirectory;
      }
    });
  });
}
