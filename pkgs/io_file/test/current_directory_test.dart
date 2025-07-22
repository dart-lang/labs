// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:io_file/io_file.dart';
import 'package:io_file/windows_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'file_system_file_utils.dart' hide fileUtils;
import 'test_utils.dart';

void tests(FileUtils utils, FileSystem fs) {
  late String tmp;
  late String cwd;

  setUp(() {
    tmp = utils.createTestDirectory('createDirectory');
    cwd = fileSystem.currentDirectory;
    fileSystem.currentDirectory = tmp;
  });

  tearDown(() {
    fileSystem.currentDirectory = cwd;
    utils.deleteDirectoryTree(tmp);
  });

  test('absolute path', () {
    final path = '$tmp/dir';
    utils.createDirectory(path);
    fs.currentDirectory = path;

    expect(
      fs.same(fs.currentDirectory, path),
      isTrue,
      reason:
          '${fs.currentDirectory} is a diffent directory than'
          '$path',
    );
    expect(
      p.isAbsolute(fs.currentDirectory),
      isTrue,
      reason: '${fs.currentDirectory} is not absolute',
    );
  });

  test('absolute path, too long path', () {
    // On Windows, limited to MAX_PATH (260) characters.
    final path = p.join(tmp, 'a' * 200, 'b' * 200);
    io.Directory(path).createSync(recursive: true);
    final oldCurrentDirectory = fs.currentDirectory;

    expect(
      () => fs.currentDirectory = path,
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
    expect(fs.currentDirectory, oldCurrentDirectory);
  }, skip: fs is! WindowsFileSystem);

  test('relative path', () {
    final path = '$tmp/dir';
    utils.createDirectory(path);

    fs.currentDirectory = 'dir';

    expect(
      fs.same(fs.currentDirectory, path),
      isTrue,
      reason:
          '${fs.currentDirectory} is a diffent directory than '
          '$path',
    );
    expect(
      p.isAbsolute(fs.currentDirectory),
      isTrue,
      reason: '${fs.currentDirectory} is not absolute',
    );
  });
}

void main() {
  group('currentDirectory', () {
    group('dart:io verification', () => tests(fileUtils(), fileSystem));
    group(
      'self verification',
      () => tests(FileSystemFileUtils(fileSystem), fileSystem),
    );
  });
}
