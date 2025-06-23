// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('ios || mac-os')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:io_file/src/vm_posix_file_system.dart';
import 'package:stdlibc/stdlibc.dart' as stdlibc;
import 'package:test/test.dart';

import 'test_utils.dart';

@Native<Int Function(Pointer<Utf8>, Uint32)>(isLeaf: false)
external int chflags(Pointer<Utf8> buf, int count);

void main() {
  final posixFileSystem = PosixFileSystem();

  group('apple metadata', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('createDirectory');
      cwd = posixFileSystem.currentDirectory;
      posixFileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      posixFileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    group('isHidden', () {
      test('false', () {
        final path = '$tmp/file';
        File(path).writeAsStringSync('Hello World');

        final data = posixFileSystem.metadata(path);
        expect(data.isHidden, isFalse);
      });
      test('true', () {
        final path = '$tmp/file';
        File(path).writeAsStringSync('Hello World');
        using((arena) {
          chflags(path.toNativeUtf8(), stdlibc.UF_HIDDEN);
        });

        final data = posixFileSystem.metadata(path);
        expect(data.isHidden, isTrue);
      });
    });
  });
}
