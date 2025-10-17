// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:unix_api/unix_api.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('mmap', () {
    const allocationSize = 1024 * 1024;
    late Directory tmp;
    late ffi.Arena arena;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('mmap');
      arena = ffi.Arena();
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
      arena.releaseAll();
    });

    test('mlock/munlock success', () {
      final address = mmap(
        nullptr,
        allocationSize,
        PROT_READ | PROT_WRITE,
        MAP_SHARED | MAP_ANONYMOUS,
        -1,
        0,
      );
      expect(address, isNot(MAP_FAILED));
      addTearDown(() => munmap(address, allocationSize));

      var r = mlock(address, allocationSize);

      expect(r, 0);

      r = munlock(address, allocationSize);
      expect(r, 0);
    });

    test('mmap/munmap success', () {
      final path = p.join(tmp.path, 'test1');

      File(path).writeAsBytesSync([0, 1, 2, 3]);

      final fd = open(
        path.toNativeUtf8(allocator: arena).cast(),
        O_RDONLY | O_CLOEXEC,
        0,
      );
      expect(fd, isNot(0));
      addTearDown(() => close(fd));

      final address = mmap(
        nullptr,
        allocationSize,
        PROT_READ,
        MAP_SHARED,
        fd,
        0,
      );
      expect(address, isNot(MAP_FAILED));

      expect(address.cast<Uint8>().value, 0);
      expect((address.cast<Uint8>() + 1).value, 1);
      expect((address.cast<Uint8>() + 2).value, 2);
      expect((address.cast<Uint8>() + 3).value, 3);

      int r = munmap(address, allocationSize);
      expect(r, 0);
    });

    test('mmap failure', () {
      final address = mmap(nullptr, 0, PROT_READ, MAP_SHARED, -1, 0);

      expect(address, MAP_FAILED);
      expect(errno, EINVAL);
    });

    test('mprotect success', () {
      final address = mmap(
        nullptr,
        allocationSize,
        PROT_READ,
        MAP_SHARED | MAP_ANONYMOUS,
        -1,
        0,
      );
      expect(address, isNot(MAP_FAILED));
      addTearDown(() => munmap(address, allocationSize));

      int r = mprotect(address, allocationSize, PROT_WRITE);

      expect(r, 0);
      address.cast<Uint8>().value = 3;
    });
  });
}
