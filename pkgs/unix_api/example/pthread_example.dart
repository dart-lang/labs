// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:unix_api/src/libc_bindings.g.dart';
import 'package:unix_api/unix_api.dart';

typedef pthread_create_callback = Pointer<Void> Function(Pointer<Void>);

void main() async {
  final arena = Arena();
  final mutex1 = arena<pthread_mutex_t>();
  final thread = arena<pthread_t>();

  //  assert(pthread_mutex_init(mutex1, nullptr) == 0);

  //  assert(pthread_mutex_lock(mutex1) == 0);
  write(1, "Let's go!\n".toNativeUtf8().cast(), "Let's go!\n".length);

  final threadCallback =
      NativeCallable<pthread_create_callback>.isolateGroupBound((
        Pointer<Void> arg,
      ) {
        write(1, "Waiting...\n".toNativeUtf8().cast(), "Waiting...\n".length);
        //        assert(pthread_mutex_lock(mutex1) == 0);
        return nullptr;
      });

  assert(
    pthread_create(thread, nullptr, threadCallback.nativeFunction, nullptr) ==
        0,
  );
  print("Thread created!");
  assert(pthread_detach(thread.ref) == 0);
  await Future.delayed(const Duration(seconds: 5));
  print("Done!");
  //  assert(pthread_mutex_unlock(mutex1) == 0);
}
