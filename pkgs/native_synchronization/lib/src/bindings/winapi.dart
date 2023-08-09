// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi';

final class SRWLOCK extends Opaque {}

final class CONDITION_VARIABLE extends Opaque {}

@Native<Void Function(Pointer<SRWLOCK>)>()
external void InitializeSRWLock(Pointer<SRWLOCK> lock);

@Native<Void Function(Pointer<SRWLOCK>)>()
external void AcquireSRWLockExclusive(Pointer<SRWLOCK> lock);

@Native<Void Function(Pointer<SRWLOCK>)>()
external void ReleaseSRWLockExclusive(Pointer<SRWLOCK> mutex);

@Native<Void Function(Pointer<CONDITION_VARIABLE>)>()
external void InitializeConditionVariable(Pointer<CONDITION_VARIABLE> condVar);

@Native<
    Int Function(
        Pointer<CONDITION_VARIABLE>, Pointer<SRWLOCK>, Uint32, Uint32)>()
external int SleepConditionVariableSRW(Pointer<CONDITION_VARIABLE> condVar,
    Pointer<SRWLOCK> srwLock, int timeOut, int flags);

@Native<Void Function(Pointer<CONDITION_VARIABLE>)>()
external void WakeConditionVariable(Pointer<CONDITION_VARIABLE> condVar);
