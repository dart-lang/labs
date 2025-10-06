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
    test('rename success', () {
      final oldPath = p.join(tmp.path, 'test1');
      final newPath = p.join(tmp.path, 'test2');
      File(oldPath).createSync();

      expect(
        rename(
          oldPath.toNativeUtf8(allocator: arena).cast(),
          newPath.toNativeUtf8(allocator: arena).cast(),
        ),
        0,
      );

      expect(File(newPath).existsSync(), isTrue);
    });

    test('rename failure', () {
      final oldPath = p.join(tmp.path, 'test1');
      final newPath = p.join(tmp.path, 'test2');

      expect(
        rename(
          oldPath.toNativeUtf8(allocator: arena).cast(),
          newPath.toNativeUtf8(allocator: arena).cast(),
        ),
        -1,
      );

      expect(errno, ENOENT);
    });
  });
}
