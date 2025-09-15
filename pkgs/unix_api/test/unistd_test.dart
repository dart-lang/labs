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
    late ffi.Arena arena;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('stdio');
      arena = ffi.Arena();
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
      arena.releaseAll();
    });

    test('access', () {
      final path = p.join(tmp.path, 'test1');

      File(path).createSync();

      expect(access(path.toNativeUtf8(allocator: arena).cast(), F_OK), 0);
    });

    test('alarm', () {
      alarm(60);

      // Cancels the previous alarm and returns how many seconds remaining.
      expect(alarm(0), allOf([lessThanOrEqualTo(60), greaterThan(55)]));
    });

    test('chdir/getcwd', () {
      final path = p.join(tmp.path, 'dir');

      Directory(path).createSync();

      final oldCwd = arena<Char>(PATH_MAX);
      final newCwd = arena<Char>(PATH_MAX);

      expect(getcwd(oldCwd, PATH_MAX), oldCwd);

      expect(chdir(path.toNativeUtf8().cast()), 0);
      addTearDown(() => chdir(oldCwd));
      expect(getcwd(newCwd, PATH_MAX), newCwd);

      // On macOS, the temporary directory may refer to a symbolic link.
      expect(
        Directory(
          newCwd.cast<ffi.Utf8>().toDartString(),
        ).resolveSymbolicLinksSync(),
        Directory(path).resolveSymbolicLinksSync(),
      );
    });

    test('close/open', () {
      final path = p.join(tmp.path, 'test1');

      File(path).createSync();

      final fd = open(
        path.toNativeUtf8(allocator: arena).cast(),
        O_RDONLY | O_CLOEXEC,
        0,
      );
      expect(fd, isNot(0));

      expect(close(fd), 0);
    });

    test('crypt', () {
      final encrypted = crypt(
        "hello".toNativeUtf8(allocator: arena).cast(),
        "salt".toNativeUtf16(allocator: arena).cast(),
      );
      expect(encrypted, isNot(nullptr));
    }, skip: Platform.isAndroid ? 'not implemeneted' : false);

    test('ctermid', () {
      final buffer = arena<Char>(L_ctermid);
      buffer[0] = 0;

      ctermid(buffer);

      expect(buffer[0], isNot(0));
    }, skip: Platform.isAndroid ? 'not implemeneted' : false);

    test('dup', () {
      final path = p.join(tmp.path, 'test1');

      File(path).writeAsStringSync('Hello World!');

      final fd1 = open(
        path.toNativeUtf8(allocator: arena).cast(),
        O_RDONLY | O_CLOEXEC,
        0,
      );
      expect(fd1, isNot(0));
      addTearDown(() => close(fd1));

      final fd2 = dup(fd1);
      expect(fd2, greaterThan(0));
      addTearDown(() => close(fd2));
    });

    test('dup2', () {
      final path = p.join(tmp.path, 'test1');

      File(path).writeAsStringSync('Hello World!');

      final fd1 = open(
        path.toNativeUtf8(allocator: arena).cast(),
        O_RDONLY | O_CLOEXEC,
        0,
      );
      expect(fd1, isNot(0));

      final fd2 = open(
        path.toNativeUtf8(allocator: arena).cast(),
        O_RDONLY | O_CLOEXEC,
        0,
      );
      expect(fd2, isNot(0));

      expect(dup2(fd1, fd2), isNot(-1));
      close(fd2);
    });

    test('fchdir', () {
      final path = p.join(tmp.path, 'dir');

      Directory(path).createSync();

      final oldCwd = arena<Char>(PATH_MAX);

      expect(getcwd(oldCwd, PATH_MAX), oldCwd);
      addTearDown(() => chdir(oldCwd));

      final newDirFd = open(path.toNativeUtf8().cast(), O_DIRECTORY, 0);
      expect(newDirFd, isNot(-1));
      addTearDown(() => close(newDirFd));

      expect(fchdir(newDirFd), 0);
    });

    test('fdatasync', () {
      final path = p.join(tmp.path, 'test1');

      File(path).createSync();

      final fd = open(
        path.toNativeUtf8(allocator: arena).cast(),
        O_RDONLY | O_CLOEXEC,
        0,
      );
      expect(fd, isNot(0));
      addTearDown(() => close(fd));

      fdatasync(fd);
    });

    test('unlink', () {
      final path = p.join(tmp.path, 'test1');

      File(path).createSync();

      expect(unlink(path.toNativeUtf8().cast()), 0);

      expect(File(path).existsSync(), isFalse);
    });

    test('unlinkat', () {
      final path = p.join(tmp.path, 'test1');

      File(path).createSync();

      expect(unlinkat(AT_FDCWD, path.toNativeUtf8().cast(), 0), 0);

      expect(File(path).existsSync(), isFalse);
    });
  });
}
