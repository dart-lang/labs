// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'errno.dart';
import 'libc_bindings.g.dart';
export 'libc_bindings.g.dart'
    show DIR, dirent, Stat, timespec, pthread_t, pthread_attr_t;

/// Gets metadata for a file.
///
/// See the [POSIX specification for `stat`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/stat.html).
int stat(ffi.Pointer<ffi.Char> path, ffi.Pointer<Stat> buf) =>
    libc_shim_stat(path, buf, errnoPtr);

/// Gets metadata for a file.
///
/// Does not resolve symlinks.
///
/// See the [POSIX specification for `lstat`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/stat.html).
int lstat(ffi.Pointer<ffi.Char> path, ffi.Pointer<Stat> buf) =>
    libc_shim_lstat(path, buf, errnoPtr);

/// Gets metadata for a file descriptor.
///
/// See the [POSIX specification for `fstat`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/stat.html).
int fstat(int fd, ffi.Pointer<Stat> buf) => libc_shim_fstat(fd, buf, errnoPtr);

/// Gets metadata for a file with its behavior controlled by a flag.
///
/// See the [POSIX specification for `fstatat`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/stat.html).
int fstatat(
  int fd,
  ffi.Pointer<ffi.Char> path,
  ffi.Pointer<Stat> buf,
  int flag,
) => libc_shim_fstatat(fd, path, buf, flag, errnoPtr);

/// Closes a directory stream.
///
/// See the [POSIX specification for `closedir`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/closedir.html).
int closedir(ffi.Pointer<DIR> d) => libc_shim_closedir(d, errnoPtr);

/// Opens a directory using a file descriptor.
///
/// See the [POSIX specification for `fdopendir`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/fdopendir.html).
ffi.Pointer<DIR> fdopendir(int fd) => libc_shim_fdopendir(fd, errnoPtr);

/// Opens a directory.
///
/// See the [POSIX specification for `fdopendir`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/opendir.html).
ffi.Pointer<DIR> opendir(ffi.Pointer<ffi.Char> path) =>
    libc_shim_opendir(path, errnoPtr);

/// Reads a directory.
///
/// See the [POSIX specification for `readdir`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/readdir.html).
ffi.Pointer<dirent> readdir(ffi.Pointer<DIR> d) =>
    libc_shim_readdir(d, errnoPtr);

extension DirentPtrExtensions on ffi.Pointer<dirent> {
  /// The `d_name` member of a `dirent` `struct`.
  ///
  /// Need because of https://github.com/dart-lang/sdk/issues/41237.
  ffi.Pointer<ffi.Char> get d_name_ptr => libc_shim_d_name_ptr(this);
}

// <pthread.h>

/// Unlocks all threads waiting on a condition variable.
///
/// See the [POSIX specification for `pthread_cond_broadcast`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_cond_broadcast.html).
int pthread_cond_broadcast(ffi.Pointer<pthread_cond_t> cond) =>
    libc_shim_pthread_cond_broadcast(cond, errnoPtr);

/// Destroys a condition variable.
///
/// See the [POSIX specification for `pthread_cond_destroy`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_cond_destroy.html).
int pthread_cond_destroy(ffi.Pointer<pthread_cond_t> cond) =>
    libc_shim_pthread_cond_destroy(cond, errnoPtr);

/// Initializes a condition variable.
///
/// See the [POSIX specification for `pthread_cond_init`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_cond_init.html).
int pthread_cond_init(
  ffi.Pointer<pthread_cond_t> cond,
  ffi.Pointer<pthread_condattr_t> attr,
) => libc_shim_pthread_cond_init(cond, attr, errnoPtr);

/// Unlocks one thread waiting on a condition variable.
///
/// See the [POSIX specification for `pthread_cond_signal`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_cond_signal.html).
int pthread_cond_signal(ffi.Pointer<pthread_cond_t> cond) =>
    libc_shim_pthread_cond_signal(cond, errnoPtr);

/// Waits on a condition variable for a given amount of time.
///
/// See the [POSIX specification for `pthread_cond_timedwait`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_cond_timedwait.html).
int pthread_cond_timedwait(
  ffi.Pointer<pthread_cond_t> cond,
  ffi.Pointer<pthread_mutex_t> mutex,
  ffi.Pointer<timespec> abstime,
) => libc_shim_pthread_cond_timedwait(cond, mutex, abstime, errnoPtr);

/// Waits on a condition variable.
///
/// See the [POSIX specification for `pthread_cond_wait`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_cond_wait.html).
int pthread_cond_wait(
  ffi.Pointer<pthread_cond_t> cond,
  ffi.Pointer<pthread_mutex_t> mutex,
) => libc_shim_pthread_cond_wait(cond, mutex, errnoPtr);

/// Creates a new thread.
///
/// See the [POSIX specification for `pthread_create`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_create.html).
int pthread_create(
  ffi.Pointer<pthread_t> thread,
  ffi.Pointer<pthread_attr_t> attr,
  ffi.Pointer<
    ffi.NativeFunction<ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Void>)>
  >
  start_routine,
  ffi.Pointer<ffi.Void> arg,
) => libc_shim_pthread_create(thread, attr, start_routine, arg, errnoPtr);

/// Detaches a thread.
///
/// See the [POSIX specification for `pthread_detach`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_detach.html).
int pthread_detach(pthread_t thread) =>
    libc_shim_pthread_detach(thread, errnoPtr);

/// Destroys a mutex.
///
/// See the [POSIX specification for `pthread_mutex_destroy`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_destroy.html).
int pthread_mutex_destroy(ffi.Pointer<pthread_mutex_t> mutex) =>
    libc_shim_pthread_mutex_destroy(mutex, errnoPtr);

/// Initializes a mutex.
///
/// See the [POSIX specification for `pthread_mutex_init`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_init.html).
int pthread_mutex_init(
  ffi.Pointer<pthread_mutex_t> mutex,
  ffi.Pointer<pthread_mutexattr_t> attr,
) => libc_shim_pthread_mutex_init(mutex, attr, errnoPtr);

/// Locks a mutex.
///
/// See the [POSIX specification for `pthread_mutex_lock`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_lock.html).
int pthread_mutex_lock(ffi.Pointer<pthread_mutex_t> mutex) =>
    libc_shim_pthread_mutex_lock(mutex, errnoPtr);

/// Locks a mutex, failing if the lock is not acquired before a timeout.
///
/// See the [POSIX specification for `pthread_mutex_timedlock`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_timedlock.html).
int pthread_mutex_timedlock(
  ffi.Pointer<pthread_mutex_t> mutex,
  ffi.Pointer<timespec> abs_timeout,
) => libc_shim_pthread_mutex_timedlock(mutex, abs_timeout, errnoPtr);

/// Unlocks a mutex.
///
/// See the [POSIX specification for `pthread_mutex_unlock`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutex_unlock.html).
int pthread_mutex_unlock(ffi.Pointer<pthread_mutex_t> mutex) =>
    libc_shim_pthread_mutex_unlock(mutex, errnoPtr);
