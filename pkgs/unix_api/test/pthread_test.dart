// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as ffi;
import 'package:unix_api/unix_api.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

// typedef pthread_create_callback = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Void>);
typedef pthread_create_callback = ffi.Void Function(ffi.Pointer<ffi.Void>);

void main() {
  group('pthread', () {
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

    test('pthread_create', () {
      final thread = arena<pthread_t>();

      final threadCallback = NativeCallable<pthread_create_callback>.listener((
        ffi.Pointer<ffi.Void> arg,
      ) {
        print('Hest');
      });

      pthread_create(
        thread,
        nullptr,
        threadCallback.nativeFunction.cast(),
        nullptr,
      );
    });
  });
}
