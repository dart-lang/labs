// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:errno/errno.dart';
import 'package:io_file/io_file.dart';
import 'package:io_file/src/fake_posix_file_system.dart';
import 'package:io_file/windows_file_system.dart';
import 'package:test/test.dart';

import 'errors.dart' as errors;
import 'test_utils.dart';
import 'test_utils_self.dart' show SelfTestUtils;

void testDirectory(FileSystem fs, TestUtils testUtils) {
  group('createDirectory', () {
    late String tmp;

    setUp(() => tmp = testUtils.createTestDirectory('createDirectory'));

    tearDown(() => testUtils.deleteDirectoryTree(tmp));

    //TODO(brianquinlan): test with a very long path.

    test('success', () {
      final path = '$tmp/dir';

      fs.createDirectory(path);
      expect(testUtils.isDir(path), isTrue);
    });

    test('create in non-existent directory', () {
      final path = '$tmp/foo/dir';

      expect(
        () => fs.createDirectory(path),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having(
                (e) => e.systemCall?.errorCode,
                'errorCode',
                fs is WindowsFileSystem
                    ? WindowsErrors.pathNotFound
                    : errors.enoent,
              ),
        ),
      );
    });

    test('create over existing directory', () {
      final path = '$tmp/dir';
      testUtils.createDirectory(path);

      expect(
        () => fs.createDirectory(path),
        throwsA(
          isA<PathExistsException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having(
                (e) => e.systemCall?.errorCode,
                'errorCode',
                fs is WindowsFileSystem
                    ? WindowsErrors.alreadyExists
                    : errors.eexist,
              ),
        ),
      );
    });

    test('create over existing file', () {
      final path = '$tmp/file';
      testUtils.createTextFile(path, 'Hello World!');

      expect(
        () => fs.createDirectory(path),
        throwsA(
          isA<PathExistsException>()
              .having((e) => e.message, 'message', 'create directory failed')
              .having(
                (e) => e.systemCall?.errorCode,
                'errorCode',
                fs is WindowsFileSystem
                    ? WindowsErrors.alreadyExists
                    : errors.eexist,
              ),
        ),
      );
    });
  });
}

void main() {
  group('default', () {
    testDirectory(fileSystem, testUtils());
  });

  group('fake', () {
    final fs = FakePosixFileSystem();
    testDirectory(fs, SelfTestUtils(fs));
  });
}
