// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:unix_api/unix_api.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('stdio', () {
    late Directory tmp;
    late ffi.Arena arena;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('stdio');
      arena = ffi.Arena();
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
      arena.releaseAll();
    });

    test('open suceeded', () {
      final path1 = p.join(tmp.path, 'test1');

      final fd = open(
        path1.toNativeUtf8(allocator: arena).cast(),
        O_CREAT,
        438, // => 0666 => rw-rw-rw-
      );

      expect(fd, isNot(-1));
    });

    test('open failure', () {
      final nonExistantPath = p.join(tmp.path, 'test1');

      final fd = open(
        nonExistantPath.toNativeUtf8(allocator: arena).cast(),
        O_RDONLY,
        0,
      );

      expect(fd, -1);
      expect(errno, ENOENT);
    });

    test('openat suceeded', () {
      final path1 = p.join(tmp.path, 'test1');

      final fd = openat(
        AT_FDCWD,
        path1.toNativeUtf8(allocator: arena).cast(),
        O_CREAT,
        438, // => 0666 => rw-rw-rw-
      );

      expect(fd, isNot(-1));
    });

    test('openat failure', () {
      final nonExistantPath = p.join(tmp.path, 'test1');

      final fd = openat(
        AT_FDCWD,
        nonExistantPath.toNativeUtf8(allocator: arena).cast(),
        O_RDONLY,
        0,
      );

      expect(fd, -1);
      expect(errno, ENOENT);
    });
  });
}
