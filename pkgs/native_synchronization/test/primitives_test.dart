// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:native_synchronization/primitives.dart';
import 'package:native_synchronization/sendable.dart';
import 'package:test/test.dart';

void main() {
  group('mutex', () {
    test('simple', () {
      final mutex = Mutex();
      expect(mutex.runLocked(() => 42), equals(42));
    });

    Future<String> spawnHelperIsolate(
        int ptrAddress, Sendable<Mutex> sendableMutex) {
      return Isolate.run(() {
        final ptr = Pointer<Uint8>.fromAddress(ptrAddress);
        final mutex = sendableMutex.materialize();

        while (true) {
          sleep(const Duration(milliseconds: 10));
          if (mutex.runLocked(() {
            if (ptr.value == 2) {
              return true;
            }
            ptr.value = 0;
            sleep(const Duration(milliseconds: 500));
            ptr.value = 1;
            return false;
          })) {
            break;
          }
        }

        return 'success';
      });
    }

    test('isolate', () async {
      await using((arena) async {
        final ptr = arena.allocate<Uint8>(1);
        final mutex = Mutex();

        final helperResult = spawnHelperIsolate(ptr.address, mutex.asSendable);

        while (true) {
          final sw = Stopwatch()..start();
          if (mutex.runLocked(() {
            if (sw.elapsedMilliseconds > 300 && ptr.value == 1) {
              ptr.value = 2;
              return true;
            }
            return false;
          })) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(await helperResult, equals('success'));
      });
    });
  });

  group('condvar', () {
    Future<String> spawnHelperIsolate(
        int ptrAddress,
        Sendable<Mutex> sendableMutex,
        Sendable<ConditionVariable> sendableCondVar) {
      return Isolate.run(() {
        final ptr = Pointer<Uint8>.fromAddress(ptrAddress);
        final mutex = sendableMutex.materialize();
        final condVar = sendableCondVar.materialize();

        return mutex.runLocked(() {
          ptr.value = 1;
          while (ptr.value == 1) {
            condVar.wait(mutex);
          }
          return ptr.value == 2 ? 'success' : 'failure';
        });
      });
    }

    test('isolate', () async {
      await using((arena) async {
        final ptr = arena.allocate<Uint8>(1);
        final mutex = Mutex();
        final condVar = ConditionVariable();

        final helperResult = spawnHelperIsolate(
            ptr.address, mutex.asSendable, condVar.asSendable);

        while (true) {
          final success = mutex.runLocked(() {
            if (ptr.value == 1) {
              ptr.value = 2;
              condVar.notify();
              return true;
            }
            return false;
          });
          if (success) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }

        expect(await helperResult, equals('success'));
      });
    });
  });
}
