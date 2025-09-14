// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:unix_api/unix_api.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('unistd', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('stdio');
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
    });

    test('access', () {
      final path = p.join(tmp.path, 'test1');

      File(path).createSync();

      ffi.using((arena) {
        expect(access(path.toNativeUtf8(allocator: arena).cast(), F_OK), 0);
      });
    });

    test('alarm', () {
      alarm(60);

      // Cancels the previous alarm and returns how many seconds remaining.
      expect(alarm(0), allOf([lessThanOrEqualTo(60), greaterThan(55)]));
    });

    test('chdir/getcwd', () {
      final path = p.join(tmp.path, 'dir');

      Directory(path).createSync();

      ffi.using((arena) {
        final oldCwd = arena<Char>(PATH_MAX);
        final newCwd = arena<Char>(PATH_MAX);

        expect(getcwd(oldCwd, PATH_MAX), isNot(nullptr));

        expect(chdir(path.toNativeUtf8().cast()), 0);
        addTearDown(() => chdir(oldCwd));
        expect(getcwd(newCwd, PATH_MAX), isNot(nullptr));

        // On macOS, the temporary directory may refer to a symbolic link.
        expect(
          Directory(
            newCwd.cast<ffi.Utf8>().toDartString(),
          ).resolveSymbolicLinksSync(),
          Directory(path).resolveSymbolicLinksSync(),
        );
      });
    });

    test('close/open', () {
      final path = p.join(tmp.path, 'test1');

      File(path).createSync();

      ffi.using((arena) {
        final fd = open(
          path.toNativeUtf8(allocator: arena).cast(),
          O_RDONLY | O_CLOEXEC,
          0,
        );
        expect(fd, isNot(0));

        expect(close(fd), 0);
      });
    });
  });
}
