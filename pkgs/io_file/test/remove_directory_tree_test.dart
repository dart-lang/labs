// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:io_file/io_file.dart';
import 'package:io_file/src/libc.dart' as libc;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;
import 'errors.dart' as errors;
import 'test_utils.dart';

// XXX try to delete . and ..

void main() {
  group('removeDirectoryTree', () {
    late String tmp;

    setUp(() => tmp = createTemp('removeDirectoryTree'));

    tearDown(() => deleteTemp(tmp));

    //TODO(brianquinlan): test with a very long path.

    test('empty', () {
      final path = '$tmp/dir';
      Directory(path).createSync();

      fileSystem.removeDirectoryTree(path);

      expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound);
    });

    test('contains single file', () {
      final path = '$tmp/dir';
      Directory(path).createSync();
      File('$path/file').writeAsStringSync('Hello World!');

      fileSystem.removeDirectoryTree(path);

      expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound);
    });

    test('contains single link', () {
      final path = '$tmp/dir';
      Directory(path).createSync();
      Link('$path/link').createSync(tmp);

      fileSystem.removeDirectoryTree(path);

      expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound);
      expect(FileSystemEntity.typeSync(tmp), FileSystemEntityType.directory);
    });

    test('contains single empty directory', () {
      final path = '$tmp/dir';
      Directory(path).createSync();
      Directory('$path/subdir').createSync();

      fileSystem.removeDirectoryTree(path);

      expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound);
    });

    test('complex tree', () {
      void createTree(String path, int depth) {
        Directory(path).createSync();

        File('$path/file1').writeAsStringSync('Hello World');
        Link('$path/filelink1').createSync('$path/file1');
        Link('$path/dirlink1').createSync(path);

        if (depth > 0) {
          createTree('$path/dir1', depth - 1);
          Link('$path/dirlink2').createSync('$path/dir1');
        }
      }

      final path = '$tmp/dir';
      createTree(path, 5);

      fileSystem.removeDirectoryTree(path);

      expect(FileSystemEntity.typeSync(path), FileSystemEntityType.notFound);
    });

    test(
      'unremoveable file',
      () {
        final path = '$tmp/dir';
        final undeletablePath = p.join(path, 'subdir1', 'subdir2', 'file1');
        Directory(path).createSync();
        Directory('$path/subdir1/subdir2').createSync(recursive: true);
        File('$path/subdir1/subdir2/file1').writeAsStringSync('Hello World');
        // r-xr-x---
        if (libc.chmod('$path/subdir1/subdir2'.toNativeUtf8().cast(), 360) ==
            -1) {
          assert(libc.errno == 0);
        }
        addTearDown(
          // rwxrwxrwx
          () => libc.chmod('$path/subdir1/subdir2'.toNativeUtf8().cast(), 511),
        );

        expect(
          () => fileSystem.removeDirectoryTree(path),
          throwsA(
            isA<PathAccessException>()
                .having((e) => e.path, 'path', undeletablePath)
                .having(
                  (e) => e.osError?.errorCode,
                  'errorCode',
                  errors.eaccess,
                ),
          ),
        );
      },
      skip:
          Platform.isWindows
              ? 'cannot change permissions on Windows (yet)'
              : false,
    );

    test(
      'unreadable directory',
      () {
        final path = '$tmp/dir';
        final unreadableDirectory = p.join(path, 'subdir1', 'subdir2');
        Directory(path).createSync();
        Directory('$path/subdir1/subdir2').createSync(recursive: true);
        File('$path/subdir1/subdir2/file1').writeAsStringSync('Hello World');
        // -wx-wx---
        if (libc.chmod('$path/subdir1/subdir2'.toNativeUtf8().cast(), 216) ==
            -1) {
          assert(libc.errno == 0);
        }
        addTearDown(
          // rwxrwxrwx
          () => libc.chmod('$path/subdir1/subdir2'.toNativeUtf8().cast(), 511),
        );

        expect(
          () => fileSystem.removeDirectoryTree(path),
          throwsA(
            isA<PathAccessException>()
                .having((e) => e.path, 'path', unreadableDirectory)
                .having(
                  (e) => e.osError?.errorCode,
                  'errorCode',
                  errors.eaccess,
                ),
          ),
        );
      },
      skip:
          Platform.isWindows
              ? 'cannot change permissions on Windows (yet)'
              : false,
    );

    test('non-existent directory', () {
      final path = '$tmp/foo/dir';

      expect(
        () => fileSystem.removeDirectoryTree(path),
        throwsA(
          isA<PathNotFoundException>().having(
            (e) => e.osError?.errorCode,
            'errorCode',
            Platform.isWindows ? win32.ERROR_PATH_NOT_FOUND : errors.enoent,
          ),
        ),
      );
    });

    test('file', () {
      final path = '$tmp/file';
      File(path).writeAsStringSync('Hello World!');

      expect(
        () => fileSystem.removeDirectoryTree(path),
        throwsA(
          isA<FileSystemException>().having(
            (e) => e.osError?.errorCode,
            'errorCode',
            Platform.isWindows ? win32.ERROR_DIRECTORY : errors.enotdir,
          ),
        ),
      );
    });

    test('file link', () {
      File('$tmp/file').writeAsStringSync('Hello World!');
      Link('$tmp/link').createSync('$tmp/file');

      expect(
        () => fileSystem.removeDirectoryTree('$tmp/link'),
        throwsA(
          isA<FileSystemException>().having(
            (e) => e.osError?.errorCode,
            'errorCode',
            Platform.isWindows ? win32.ERROR_DIRECTORY : errors.enotdir,
          ),
        ),
      );
    });

    test('directory link', () {
      File('$tmp/dir').createSync();
      Link('$tmp/link').createSync('$tmp/dir');

      expect(
        () => fileSystem.removeDirectoryTree('$tmp/link'),
        throwsA(
          isA<FileSystemException>().having(
            (e) => e.osError?.errorCode,
            'errorCode',
            Platform.isWindows ? win32.ERROR_DIRECTORY : errors.enotdir,
          ),
        ),
      );
    });
  });
}
