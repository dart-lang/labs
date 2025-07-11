// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:ffi/ffi.dart';
import 'package:io_file/io_file.dart';
import 'package:io_file/src/libc.dart' as libc;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;
import 'errors.dart' as errors;
import 'test_utils.dart';

void main() {
  group('removeDirectoryTree', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('removeDirectoryTree');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('empty', () {
      final path = '$tmp/dir';
      io.Directory(path).createSync();

      fileSystem.removeDirectoryTree(path);

      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test('absolute path, long directory name', () {
      // On Windows:
      // When using an API to create a directory, the specified path cannot be
      // so long that you cannot append an 8.3 file name (that is, the
      // directory name cannot exceed MAX_PATH minus 12).
      final dirname = 'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
      final path = p.join(tmp, dirname);
      io.Directory(path).createSync();
      io.File('$path/file').writeAsStringSync('Hello World!');

      fileSystem.removeDirectoryTree(path);

      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test('relative path, long directory name', () {
      // On Windows:
      // When using an API to create a directory, the specified path cannot be
      // so long that you cannot append an 8.3 file name (that is, the
      // directory name cannot exceed MAX_PATH minus 12).
      final path = 'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
      io.Directory(path).createSync();
      io.File('$path/file').writeAsStringSync('Hello World!');

      fileSystem.removeDirectoryTree(path);

      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test('contains single file', () {
      final path = '$tmp/dir';
      io.Directory(path).createSync();
      io.File('$path/file').writeAsStringSync('Hello World!');

      fileSystem.removeDirectoryTree(path);

      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test('contains single link', () {
      final path = '$tmp/dir';
      io.Directory(path).createSync();
      io.Link('$path/link').createSync(tmp);

      fileSystem.removeDirectoryTree(path);

      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
      expect(
        io.FileSystemEntity.typeSync(tmp),
        io.FileSystemEntityType.directory,
      );
    });

    test('contains single empty directory', () {
      final path = '$tmp/dir';
      io.Directory(path).createSync();
      io.Directory('$path/subdir').createSync();

      fileSystem.removeDirectoryTree(path);

      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test('complex tree', () {
      void createTree(String path, int depth) {
        io.Directory(path).createSync();

        io.File('$path/file1').writeAsStringSync('Hello World');
        io.Link('$path/filelink1').createSync('$path/file1');
        io.Link('$path/dirlink1').createSync(path);

        if (depth > 0) {
          createTree('$path/dir1', depth - 1);
          io.Link('$path/dirlink2').createSync('$path/dir1');
        }
      }

      final path = '$tmp/dir';
      createTree(path, 5);

      fileSystem.removeDirectoryTree(path);

      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test('complex tree of long paths', () {
      // On Windows:
      // When using an API to create a directory, the specified path cannot be
      // so long that you cannot append an 8.3 file name (that is, the
      // directory name cannot exceed MAX_PATH minus 12).
      void createTree(String path, int depth) {
        io.Directory(path).createSync();

        final filePath = 'f' * 255;
        final fileLinkPath = 'l' * 255;
        final directoryPath =
            'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
        final directoryLinkPath =
            's' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);

        io.File('$path/$filePath').writeAsStringSync('Hello World');
        io.Link('$path/$fileLinkPath').createSync('$path/file1');
        io.Link('$path/$directoryLinkPath').createSync(path);

        if (depth > 0) {
          createTree('$path/$directoryPath', depth - 1);
        }
      }

      final path = '$tmp/dir';
      // macOS has a maximum path length of 1024 characters.
      createTree(path, 2);

      fileSystem.removeDirectoryTree(path);

      expect(
        io.FileSystemEntity.typeSync(path),
        io.FileSystemEntityType.notFound,
      );
    });

    test(
      'unremoveable file',
      () {
        final path = '$tmp/dir';
        final undeletablePath = p.join(path, 'subdir1', 'subdir2', 'file1');
        io.Directory(path).createSync();
        io.Directory('$path/subdir1/subdir2').createSync(recursive: true);
        io.File('$path/subdir1/subdir2/file1').writeAsStringSync('Hello World');
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
                .having((e) => e.path1, 'path1', undeletablePath)
                .having((e) => e.errorCode, 'errorCode', errors.eaccess),
          ),
        );
      },
      skip:
          io.Platform.isWindows
              ? 'TODO(brianquinlan): make this work on Windows'
              : false,
    );

    test(
      'unreadable directory',
      () {
        final path = '$tmp/dir';
        final unreadableDirectory = p.join(path, 'subdir1', 'subdir2');
        io.Directory(path).createSync();
        io.Directory('$path/subdir1/subdir2').createSync(recursive: true);
        io.File('$path/subdir1/subdir2/file1').writeAsStringSync('Hello World');
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
                .having((e) => e.path1, 'path1', unreadableDirectory)
                .having((e) => e.errorCode, 'errorCode', errors.eaccess),
          ),
        );
      },
      skip:
          io.Platform.isWindows
              ? 'TODO(brianquinlan): make this work on Windows'
              : false,
    );

    test('non-existent directory', () {
      final path = '$tmp/foo/dir';

      expect(
        () => fileSystem.removeDirectoryTree(path),
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
        () => fileSystem.removeDirectoryTree(path),
        throwsA(
          isA<IOFileException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows ? win32.ERROR_DIRECTORY : errors.enotdir,
          ),
        ),
      );
    });

    test('file link', () {
      io.File('$tmp/file').writeAsStringSync('Hello World!');
      io.Link('$tmp/link').createSync('$tmp/file');

      expect(
        () => fileSystem.removeDirectoryTree('$tmp/link'),
        throwsA(
          isA<IOFileException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows ? win32.ERROR_DIRECTORY : errors.enotdir,
          ),
        ),
      );
    });

    test('directory link', () {
      io.File('$tmp/dir').createSync();
      io.Link('$tmp/link').createSync('$tmp/dir');

      expect(
        () => fileSystem.removeDirectoryTree('$tmp/link'),
        throwsA(
          isA<IOFileException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows ? win32.ERROR_DIRECTORY : errors.enotdir,
          ),
        ),
      );
    });
  });
}
