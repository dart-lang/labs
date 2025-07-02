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
  group('createTemporaryDirectory', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('createTemporaryDirectory');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('no arguments', () {
      final tmp1 = fileSystem.createTemporaryDirectory();
      addTearDown(() => io.Directory(tmp1).deleteSync());
      final tmp2 = fileSystem.createTemporaryDirectory();
      addTearDown(() => io.Directory(tmp2).deleteSync());

      expect(fileSystem.same(tmp1, tmp2), isFalse);
      expect(io.Directory(tmp1).existsSync(), isTrue);
      expect(io.Directory(tmp2).existsSync(), isTrue);
    });

    test('prefix', () {
      final tmp1 = fileSystem.createTemporaryDirectory(prefix: 'myprefix');
      addTearDown(() => io.Directory(tmp1).deleteSync());
      final tmp2 = fileSystem.createTemporaryDirectory(prefix: 'myprefix');
      addTearDown(() => io.Directory(tmp2).deleteSync());

      expect(tmp1, contains('myprefix'));
      expect(tmp2, contains('myprefix'));
      expect(fileSystem.same(tmp1, tmp2), isFalse);
      expect(io.Directory(tmp1).existsSync(), isTrue);
      expect(io.Directory(tmp2).existsSync(), isTrue);
    });

    test('prefix is empty string', () {
      final tmp1 = fileSystem.createTemporaryDirectory(prefix: '');
      addTearDown(() => io.Directory(tmp1).deleteSync());
      final tmp2 = fileSystem.createTemporaryDirectory(prefix: '');
      addTearDown(() => io.Directory(tmp2).deleteSync());

      expect(fileSystem.same(tmp1, tmp2), isFalse);
      expect(io.Directory(tmp1).existsSync(), isTrue);
      expect(io.Directory(tmp2).existsSync(), isTrue);
    });

    test('prefix contains XXXXXX', () {
      final tmp1 = fileSystem.createTemporaryDirectory(
        prefix: 'myprefix-XXXXXX',
      );
      addTearDown(() => io.Directory(tmp1).deleteSync());
      final tmp2 = fileSystem.createTemporaryDirectory(
        prefix: 'myprefix-XXXXXX',
      );
      addTearDown(() => io.Directory(tmp2).deleteSync());

      expect(tmp1, contains('myprefix-'));
      expect(tmp2, contains('myprefix-'));
      expect(fileSystem.same(tmp1, tmp2), isFalse);
      expect(io.Directory(tmp1).existsSync(), isTrue);
      expect(io.Directory(tmp2).existsSync(), isTrue);
    });

    test('parent', () {
      final tmp1 = fileSystem.createTemporaryDirectory(parent: tmp);
      final tmp2 = fileSystem.createTemporaryDirectory(parent: tmp);

      expect(tmp1, startsWith(tmp));
      expect(tmp2, startsWith(tmp));
      expect(fileSystem.same(tmp1, tmp2), isFalse);
      expect(io.Directory(tmp1).existsSync(), isTrue);
      expect(io.Directory(tmp2).existsSync(), isTrue);
    });

    test('parent has a long directory name', () {
      // On Windows:
      // When using an API to create a directory, the specified path cannot be
      // so long that you cannot append an 8.3 file name (that is, the directory
      // name cannot exceed MAX_PATH minus 12).
      final dirname = 'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
      final parent = p.join(tmp, dirname);
      io.Directory(parent).createSync();

      final tmp1 = fileSystem.createTemporaryDirectory(parent: parent);
      final tmp2 = fileSystem.createTemporaryDirectory(parent: parent);

      expect(tmp1, startsWith(tmp));
      expect(tmp2, startsWith(tmp));
      expect(fileSystem.same(tmp1, tmp2), isFalse);
      expect(io.Directory(tmp1).existsSync(), isTrue);
      expect(io.Directory(tmp2).existsSync(), isTrue);
    });

    test('parent is empty string', () {
      final tmp1 = fileSystem.createTemporaryDirectory(parent: '');
      addTearDown(() => io.Directory(tmp1).deleteSync());
      final tmp2 = fileSystem.createTemporaryDirectory(parent: '');
      addTearDown(() => io.Directory(tmp2).deleteSync());

      expect(p.isRelative(tmp1), isTrue);
      expect(p.isRelative(tmp2), isTrue);
      expect(fileSystem.same(tmp1, tmp2), isFalse);
      expect(io.Directory(tmp1).existsSync(), isTrue);
      expect(io.Directory(tmp2).existsSync(), isTrue);
    });

    test('parent does not exist', () {
      expect(
        () => fileSystem.createTemporaryDirectory(parent: '/foo/bar/baz'),
        throwsA(
          isA<PathNotFoundException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows ? win32.ERROR_PATH_NOT_FOUND : errors.enoent,
          ),
        ),
      );
    });

    test('prefix is absolute path inside of parent', () {
      final subdir1 = '$tmp/dir1';
      io.Directory(subdir1).createSync();

      final tmp1 = fileSystem.createTemporaryDirectory(
        parent: subdir1,
        prefix: '$subdir1/file',
      );

      expect(tmp1, startsWith(subdir1));
    });

    test('prefix is absolute path outside of parent', () {
      final subdir1 = '$tmp/dir1';
      final subdir2 = '$tmp/dir2';
      io.Directory(subdir1).createSync();
      io.Directory(subdir2).createSync();

      final tmp1 = fileSystem.createTemporaryDirectory(
        parent: subdir1,
        prefix: '$subdir2/file',
      );

      expect(tmp1, startsWith(subdir2));
    });

    test('prefix is non-existant path inside temp directory', () {
      expect(
        () => fileSystem.createTemporaryDirectory(prefix: 'subdir/file'),
        throwsA(
          isA<PathNotFoundException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows ? win32.ERROR_PATH_NOT_FOUND : errors.enoent,
          ),
        ),
      );
    });

    test('prefix is existant path inside temp directory', () {
      final subdir1 = '$tmp/dir1';
      io.Directory(subdir1).createSync();

      final tmp1 = fileSystem.createTemporaryDirectory(
        parent: tmp,
        prefix: 'dir1/file',
      );
      expect(p.canonicalize(tmp1), startsWith(p.canonicalize(subdir1)));
      expect(io.Directory(tmp1).existsSync(), isTrue);
    });
  });
}
