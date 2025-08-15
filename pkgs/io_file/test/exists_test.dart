// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:io_file/io_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'file_system_file_utils.dart' hide fileUtils;
import 'test_utils.dart';

void tests(FileUtils utils, FileSystem fs) {
  late String tmp;
  late String cwd;

  setUp(() {
    tmp = utils.createTestDirectory('exists');
    cwd = fs.currentDirectory;
    fs.currentDirectory = tmp;
  });

  tearDown(() {
    fs.currentDirectory = cwd;
    utils.deleteDirectoryTree(tmp);
  });

  test('file exists', () {
    final path = p.join(tmp, 'file');
    utils.createTextFile(path, '');
    expect(fs.exists(path), isTrue);
  });

  test('directory exists', () {
    final path = p.join(tmp, 'dir');
    utils.createDirectory(path);
    expect(fs.exists(path), isTrue);
  });

  test('link to file exists', () {
    final filePath = p.join(tmp, 'file');
    final linkPath = p.join(tmp, 'link');
    utils.createTextFile(filePath, '');
    io.Link(linkPath).createSync(filePath);
    expect(fs.exists(linkPath), isTrue);
  });

  test('link to directory exists', () {
    final dirPath = p.join(tmp, 'dir');
    final linkPath = p.join(tmp, 'link');
    utils.createDirectory(dirPath);
    io.Link(linkPath).createSync(dirPath);
    expect(fs.exists(linkPath), isTrue);
  });

  test('broken link exists', () {
    final linkPath = p.join(tmp, 'link');
    io.Link(linkPath).createSync('non-existent');
    expect(fs.exists(linkPath), isTrue);
  });

  test('path does not exist', () {
    final path = p.join(tmp, 'non-existent');
    expect(fs.exists(path), isFalse);
  });

  test('path in non-existent directory does not exist', () {
    final path = p.join(tmp, 'non-existent-dir', 'file');
    expect(fs.exists(path), isFalse);
  });

  test('empty path does not exist', () {
    expect(fs.exists(''), isFalse);
  });

  test('long file path exists', () {
    final longPath = p.join(tmp, 'a' * 255);
    utils.createTextFile(longPath, '');
    expect(fs.exists(longPath), isTrue);
  });
}

void main() {
  group('exists', () {
    group('dart:io verification', () => tests(fileUtils(), fileSystem));
    group(
      'self verification',
      () => tests(FileSystemFileUtils(fileSystem), fileSystem),
    );
  });
}
