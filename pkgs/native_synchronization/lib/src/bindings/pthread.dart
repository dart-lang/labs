// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi';

final class pthread_mutex_t extends Opaque {}

final class pthread_cond_t extends Opaque {}

@Native<Int Function(Pointer<pthread_mutex_t>, Pointer<Void>)>()
external int pthread_mutex_init(
    Pointer<pthread_mutex_t> mutex, Pointer<Void> attrs);

@Native<Int Function(Pointer<pthread_mutex_t>)>()
external int pthread_mutex_lock(Pointer<pthread_mutex_t> mutex);

@Native<Int Function(Pointer<pthread_mutex_t>)>()
external int pthread_mutex_unlock(Pointer<pthread_mutex_t> mutex);

@Native<Int Function(Pointer<pthread_mutex_t>)>()
external int pthread_mutex_destroy(Pointer<pthread_mutex_t> cond);

@Native<Int Function(Pointer<pthread_cond_t>, Pointer<Void>)>()
external int pthread_cond_init(
    Pointer<pthread_cond_t> cond, Pointer<Void> attrs);

@Native<Int Function(Pointer<pthread_cond_t>, Pointer<pthread_mutex_t>)>()
external int pthread_cond_wait(
    Pointer<pthread_cond_t> cond, Pointer<pthread_mutex_t> mutex);

@Native<Int Function(Pointer<pthread_cond_t>)>()
external int pthread_cond_destroy(Pointer<pthread_cond_t> cond);

@Native<Int Function(Pointer<pthread_cond_t>)>()
external int pthread_cond_signal(Pointer<pthread_cond_t> cond);
