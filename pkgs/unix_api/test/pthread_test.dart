// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart' as ffi;
import 'package:unix_api/src/libc_bindings.g.dart';
import 'package:unix_api/unix_api.dart';
import 'package:test/test.dart';

typedef pthread_create_callback = ffi.Void Function(ffi.Pointer<ffi.Void>);

void main() {
  group('pthread', () {
    late ffi.Arena arena;

    setUp(() {
      arena = ffi.Arena();
    });

    tearDown(() {
      arena.releaseAll();
    });

    test('pthread_create/pthread_detach', () async {
      final thread = arena<pthread_t>();
      final c = Completer<void>();

      final threadCallback = NativeCallable<pthread_create_callback>.listener((
        ffi.Pointer<ffi.Void> arg,
      ) async {
        c.complete();
      });

      pthread_create(
        thread,
        nullptr,
        threadCallback.nativeFunction.cast(),
        nullptr,
      );
      pthread_detach(thread.ref);

      await c.future;
    });

    test('pthread_mutex_*', () async {
      final mutex = arena<pthread_mutex_t>();
      final time = arena<timespec>();
      time.ref.tv_nsec = 0;
      time.ref.tv_sec = 0;

      expect(pthread_mutex_init(mutex, nullptr), 0);
      expect(pthread_mutex_lock(mutex), 0);
      await Isolate.run(() {
        assert(
          pthread_mutex_timedlock(mutex, time) ==
              ((Platform.isAndroid || Platform.isLinux) ? ETIMEDOUT : ENOSYS),
        );
      });

      final lockTestIsolate = Isolate.run(() {
        assert(pthread_mutex_lock(mutex) == 0);
      });
      pthread_mutex_unlock(mutex);
      await lockTestIsolate;
      assert(pthread_mutex_unlock(mutex) == 0); // Locked by Isolate.
      expect(pthread_mutex_destroy(mutex), 0);
    });

    test('pthread_cond_*', () async {
      final cond = arena<pthread_cond_t>();
      final mutex = arena<pthread_mutex_t>();
      final time = arena<timespec>();
      time.ref.tv_nsec = 0;
      time.ref.tv_sec = 0;

      expect(pthread_mutex_init(mutex, nullptr), 0);
      expect(pthread_cond_init(cond, nullptr), 0);
      expect(pthread_mutex_lock(mutex), 0);
      expect(pthread_cond_timedwait(cond, mutex, time), ETIMEDOUT);
      expect(pthread_mutex_unlock(mutex), 0);

      // Tests waiting on a signal.
      var waitOnSignalDone = false;
      Isolate.run(() {
        assert(pthread_mutex_lock(mutex) == 0);
        assert(pthread_cond_wait(cond, mutex) == 0);
        assert(pthread_mutex_unlock(mutex) == 0);
      }).whenComplete(() => waitOnSignalDone = true);

      while (!waitOnSignalDone) {
        expect(pthread_cond_signal(cond), 0);
        await Future.delayed(const Duration());
      }

      // Tests waiting on a signal.
      var waitOnSignalBroadcast = false;
      Isolate.run(() {
        assert(pthread_mutex_lock(mutex) == 0);
        assert(pthread_cond_wait(cond, mutex) == 0);
        assert(pthread_mutex_unlock(mutex) == 0);
      }).whenComplete(() => waitOnSignalBroadcast = true);

      while (!waitOnSignalBroadcast) {
        expect(pthread_cond_broadcast(cond), 0);
        await Future.delayed(const Duration());
      }

      expect(pthread_mutex_destroy(mutex), 0);
      expect(pthread_cond_destroy(cond), 0);
    });
  });
}
