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
import 'file_system_file_utils.dart' hide fileUtils;
import 'test_utils.dart';

void tests(FileUtils utils, FileSystem fs) {
  late String tmp;
  late String cwd;

  setUp(() {
    tmp = utils.createTestDirectory('createDirectory');
    cwd = fs.currentDirectory;
    fs.currentDirectory = tmp;
  });

  tearDown(() {
    fs.currentDirectory = cwd;
    utils.deleteDirectoryTree(tmp);
  });

  test('success', () {
    final path = '$tmp/dir';

    fs.createDirectory(path);
    expect(utils.isDirectory(path), isTrue);
  });

  test('absolute path, long directory name', () {
    // On Windows:
    // When using an API to create a directory, the specified path cannot be
    // so long that you cannot append an 8.3 file name (that is, the directory
    // name cannot exceed MAX_PATH minus 12).
    final dirname = 'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
    final path = p.join(tmp, dirname);

    fs.createDirectory(path);
    expect(utils.isDirectory(path), isTrue);
  });

  test('absolute path, too long directory name', () {
    final path = p.join(tmp, 'd' * 256);

    expect(
      () => fs.createDirectory(path),
      throwsA(
        isA<IOFileException>()
            .having((e) => e.path1, 'path1', path)
            .having(
              (e) => e.errorCode,
              'errorCode',
              io.Platform.isWindows
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
    final path = 'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
    fs.createDirectory(path);

    expect(utils.isDirectory(path), isTrue);
  });

  test('relative path, too long directory name', () {
    final path = 'd' * 256;

    expect(
      () => fs.createDirectory(path),
      throwsA(
        isA<IOFileException>()
            .having((e) => e.path1, 'path1', path)
            .having(
              (e) => e.errorCode,
              'errorCode',
              io.Platform.isWindows
                  ? win32.ERROR_INVALID_NAME
                  : errors.enametoolong,
            ),
      ),
    );
  });

  test('create in non-existent directory', () {
    final path = '$tmp/foo/dir';

    expect(
      () => fs.createDirectory(path),
      throwsA(
        isA<PathNotFoundException>()
            .having((e) => e.path1, 'path', path)
            .having(
              (e) => e.errorCode,
              'errorCode',
              io.Platform.isWindows
                  ? win32.ERROR_PATH_NOT_FOUND
                  : errors.enoent,
            ),
      ),
    );
  });

  test('create over existing directory', () {
    final path = '$tmp/dir';
    io.Directory(path).createSync();

    expect(
      () => fs.createDirectory(path),
      throwsA(
        isA<PathExistsException>()
            .having((e) => e.path1, 'path1', path)
            .having(
              (e) => e.errorCode,
              'errorCode',
              io.Platform.isWindows
                  ? win32.ERROR_ALREADY_EXISTS
                  : errors.eexist,
            ),
      ),
    );
  });

  test('create "."', () {
    const path = '.';
    expect(
      () => fs.createDirectory(path),
      throwsA(
        isA<PathExistsException>()
            .having((e) => e.path1, 'path1', path)
            .having(
              (e) => e.errorCode,
              'errorCode',
              io.Platform.isWindows
                  ? win32.ERROR_ALREADY_EXISTS
                  : errors.eexist,
            ),
      ),
    );
  });

  test('create ".."', () {
    const path = '..';
    expect(
      () => fs.createDirectory(path),
      throwsA(
        isA<PathExistsException>()
            .having((e) => e.path1, 'path1', path)
            .having(
              (e) => e.errorCode,
              'errorCode',
              io.Platform.isWindows
                  ? win32.ERROR_ALREADY_EXISTS
                  : errors.eexist,
            ),
      ),
    );
  });

  test('create over existing file', () {
    final path = '$tmp/file';
    io.File(path).createSync();

    expect(
      () => fs.createDirectory(path),
      throwsA(
        isA<PathExistsException>()
            .having((e) => e.path1, 'path1', path)
            .having(
              (e) => e.errorCode,
              'errorCode',
              io.Platform.isWindows
                  ? win32.ERROR_ALREADY_EXISTS
                  : errors.eexist,
            ),
      ),
    );
  });
}

void main() {
  group('createDirectory', () {
    group('dart:io verification', () => tests(fileUtils(), fileSystem));
    group(
      'self verification',
      () => tests(FileSystemFileUtils(fileSystem), fileSystem),
    );
  });
}
