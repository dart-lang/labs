// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library contains native synchronization primitives such as [Mutex]
/// and [ConditionVariable] implemented on top of low-level primitives
/// provided by the OS.
///
/// See OS specific documentation for more details:
///
/// * POSIX man pages (Linux, Android, Mac OS X and iOS X)
///     * `pthread_mutex_lock` and `pthread_mutex_unlock`,
///     * `pthread_cond_wait` and `pthread_cond_signal`.
/// * Windows
///     * [Slim Reader/Writer (SRW) Locks](https://learn.microsoft.com/en-us/windows/win32/sync/slim-reader-writer--srw--locks),
///     * [Condition Variables](https://learn.microsoft.com/en-us/windows/win32/sync/condition-variables),
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:native_synchronization/sendable.dart';

import 'package:native_synchronization/src/bindings/pthread.dart';
import 'package:native_synchronization/src/bindings/winapi.dart';

part 'posix.dart';
part 'windows.dart';

/// A *mutex* synchronization primitive.
///
/// Mutex can be used to synchronize access to a native resource shared between
/// multiple threads.
///
/// [Mutex] object can not be directly sent to other isolates via a `SendPort`,
/// but it can be converted to a `Sendable<Mutex>` via `asSendable` getter.
///
/// Mutex objects are owned by an isolate which created them.
sealed class Mutex implements Finalizable {
  Mutex._();

  factory Mutex() => Platform.isWindows ? _WindowsMutex() : _PosixMutex();

  /// Acquire exclusive ownership of this mutex.
  ///
  /// If this mutex is already acquired then an attempt to acquire it
  /// blocks the current thread until the mutex is released by the
  /// current owner.
  ///
  /// **Warning**: attempting to hold a mutex across asynchronous suspension
  /// points will lead to undefined behavior and potentially crashes.
  void _lock();

  /// Release exclusive ownership of this mutex.
  ///
  /// It is an error to release ownership of the mutex if it was not
  /// previously acquired.
  void _unlock();

  /// Run the given synchronous `action` under a mutex.
  ///
  /// This function takes exclusive ownership of the mutex, executes `action`
  /// and then releases the mutex. It returns the value returned by `action`.
  ///
  /// **Warning**: you can't combine `runLocked` with an asynchronous code.
  R runLocked<R>(R Function() action) {
    _lock();
    try {
      return action();
    } finally {
      _unlock();
    }
  }

  Sendable<Mutex> get asSendable => Sendable.wrap(
      Platform.isWindows ? _WindowsMutex.fromAddress : _PosixMutex.fromAddress,
      _address);

  int get _address;
}

/// A *condition variable* synchronization primitive.
///
/// Condition variable can be used to synchronously wait for a condition to
/// occur.
///
/// [ConditionVariable] object can not be directly sent to other isolates via a
/// `SendPort`, but it can be converted to a `Sendable<ConditionVariable>`
/// object via [asSendable] getter.
///
/// [ConditionVariable] objects are owned by an isolate which created them.
sealed class ConditionVariable implements Finalizable {
  ConditionVariable._();

  factory ConditionVariable() => Platform.isWindows
      ? _WindowsConditionVariable()
      : _PosixConditionVariable();

  /// Block and wait until another thread calls [notify].
  ///
  /// `mutex` must be a [Mutex] object exclusively held by the current thread.
  /// It will be released and the thread will block until another thread
  /// calls [notify].
  void wait(Mutex mutex);

  /// Wake up at least one thread waiting on this condition variable.
  void notify();

  Sendable<ConditionVariable> get asSendable => Sendable.wrap(
      Platform.isWindows
          ? _WindowsConditionVariable.fromAddress
          : _PosixConditionVariable.fromAddress,
      _address);

  int get _address;
}
