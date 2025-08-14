// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:io_file/io_file.dart';
import 'package:io_file/src/vm_windows_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'fifo.dart';
import 'file_system_file_utils.dart' hide fileUtils;
import 'test_utils.dart';

void tests(FileUtils utils, FileSystem fs) {
  late String tmp;
  late String cwd;

  setUp(() {
    tmp = utils.createTestDirectory('removeFile');
    cwd = fs.currentDirectory;
    fs.currentDirectory = tmp;
  });

  tearDown(() {
    fs.currentDirectory = cwd;
    utils.deleteDirectoryTree(tmp);
  });

  test('success', () {
    final path = '$tmp/file';
    utils.createTextFile(path, 'Hello World!');

    fileSystem.removeFile(path);

    expect(utils.exists(path), isFalse, reason: '$path exists');
  });

  test('absolute path, long directory name', () {
    // On Windows:
    // When using an API to create a directory, the specified path cannot be
    // so long that you cannot append an 8.3 file name (that is, the directory
    // name cannot exceed MAX_PATH minus 12).
    final dirname = 'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
    final path = p.join(tmp, dirname);
    utils.createTextFile(path, 'Hello World!');

    fileSystem.removeFile(path);

    expect(utils.exists(path), isFalse, reason: '$path exists');
  });

  test('relative path, long directory name', () {
    // On Windows:
    // When using an API to create a directory, the specified path cannot be
    // so long that you cannot append an 8.3 file name (that is, the directory
    // name cannot exceed MAX_PATH minus 12).
    final path = 'd' * (io.Platform.isWindows ? win32.MAX_PATH - 12 : 255);
    utils.createTextFile(path, 'Hello World!');

    fileSystem.removeFile(path);

    expect(utils.exists(path), isFalse, reason: '$path exists');
  });

  test('directory', () {
    // On Windows:
    // When using an API to create a directory, the specified path cannot be
    // so long that you cannot append an 8.3 file name (that is, the directory
    // name cannot exceed MAX_PATH minus 12).
    final path = p.join(tmp, 'dir');
    utils.createDirectory(path);

    expect(
      () => fileSystem.removeFile(path),
      throwsA(
        isA<PathAccessException>().having(
          (e) => e.errorCode,
          'errorCode',
          fileSystem is WindowsFileSystem
              ? win32.ERROR_PATH_NOT_FOUND
              : errors.eperm,
        ),
      ),
    );
  });

  test('link to directory', () {
    final dirPath = p.join(tmp, 'dir');
    final linkPath = p.join(tmp, 'link');
    utils.createDirectory(dirPath);
    io.Link(linkPath).createSync(dirPath);

    fileSystem.removeFile(linkPath);

    expect(utils.exists(dirPath), isTrue, reason: '$dirPath does not exist');
    expect(utils.exists(linkPath), isFalse, reason: '$linkPath exists');
  });

  test('link to file', () {
    final filePath = p.join(tmp, 'file');
    final linkPath = p.join(tmp, 'link');
    utils.createTextFile(filePath, 'Hello World!');
    io.Link(linkPath).createSync(filePath);

    fileSystem.removeFile(linkPath);

    expect(utils.exists(filePath), isTrue, reason: '$filePath does not exist');
    expect(utils.exists(linkPath), isFalse, reason: '$linkPath exists');
  });

  test('path does not exist', () {
    final path = '$tmp/file';

    expect(
      () => fileSystem.removeFile(path),
      throwsA(
        isA<PathNotFoundException>().having(
          (e) => e.errorCode,
          'errorCode',
          fileSystem is WindowsFileSystem
              ? win32.ERROR_PATH_NOT_FOUND
              : errors.enoent,
        ),
      ),
    );
  });
}

void main() {
  group('removeFile', () {
    group('dart:io verification', () => tests(fileUtils(), fileSystem));
    group(
      'self verification',
      () => tests(FileSystemFileUtils(fileSystem), fileSystem),
    );
  });
}
