// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('ios || mac-os')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:io_file/io_file.dart';
import 'package:io_file/src/vm_posix_file_system.dart';
import 'package:stdlibc/stdlibc.dart' as stdlibc;
import 'package:test/test.dart';

import 'file_system_file_utils.dart' hide fileUtils;
import 'test_utils.dart';

@Native<Int Function(Pointer<Utf8>, Uint32)>(isLeaf: false)
external int chflags(Pointer<Utf8> buf, int count);

void tests(FileUtils utils, PosixFileSystem fs) {
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
  test('false', () {
    final path = '$tmp/file';
    utils.createTextFile(path, 'Hello World');

    final data = fs.metadata(path);
    expect(data.isHidden, isFalse);
  });
  test('true', () {
    final path = '$tmp/file';
    utils.createTextFile(path, 'Hello World');
    using((arena) {
      chflags(path.toNativeUtf8(), stdlibc.UF_HIDDEN);
    });

    final data = fs.metadata(path);
    expect(data.isHidden, isTrue);
  });
}

void main() {
  group('apple metadata', () {
    group(
      'dart:io verification',
      () => tests(fileUtils(), fileSystem as PosixFileSystem),
    );
    group(
      'self verification',
      () =>
          tests(FileSystemFileUtils(fileSystem), fileSystem as PosixFileSystem),
    );
  });
}
