// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:unix_api/unix_api.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('stat', () {
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

    test('chmod success', () {
      final path = p.join(tmp.path, 'test');
      File(path).createSync();

      final r = chmod(
        path.toNativeUtf8(allocator: arena).cast(),
        438, // => 0666 => rw-rw-rw-
      );

      expect(r, 0);
    });

    test('chmod too large mode', () {
      final path = p.join(tmp.path, 'test');
      File(path).createSync();

      final r = chmod(
        path.toNativeUtf8(allocator: arena).cast(),
        0x7fffffffffffffff,
      );

      expect(r, -1);
      expect(errno, EDOM);
    });

    test('chmod failure', () {
      final path = p.join(tmp.path, 'test');

      final r = chmod(
        path.toNativeUtf8(allocator: arena).cast(),
        438, // => 0666 => rw-rw-rw-
      );

      expect(r, -1);
      expect(errno, ENOENT);
    });

    test('mkdir success', () {
      final path = p.join(tmp.path, 'test');

      final r = mkdir(
        path.toNativeUtf8(allocator: arena).cast(),
        438, // => 0666 => rw-rw-rw-
      );

      expect(r, 0);
    });

    test('mkdir failure', () {
      final path = p.join(tmp.path, 'nonexistant', 'test');

      final r = mkdir(
        path.toNativeUtf8(allocator: arena).cast(),
        438, // => 0666 => rw-rw-rw-
      );

      expect(r, -1);
      expect(errno, ENOENT);
    });
  });
}
