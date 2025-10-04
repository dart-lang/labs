// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;

import 'errno.dart';
import 'libc_bindings.g.dart';
export 'libc_bindings.g.dart' show DIR, dirent, Stat, timespec;

int stat(ffi.Pointer<ffi.Char> path, ffi.Pointer<Stat> buf) =>
    libc_shim_stat(path, buf, errnoPtr);

int lstat(ffi.Pointer<ffi.Char> path, ffi.Pointer<Stat> buf) =>
    libc_shim_lstat(path, buf, errnoPtr);

int fstat(int fd, ffi.Pointer<Stat> buf) => libc_shim_fstat(fd, buf, errnoPtr);

int fstatat(
  int fd,
  ffi.Pointer<ffi.Char> path,
  ffi.Pointer<Stat> buf,
  int flag,
) => libc_shim_fstatat(fd, path, buf, flag, errnoPtr);

int closedir(ffi.Pointer<DIR> d) => libc_shim_closedir(d, errnoPtr);

ffi.Pointer<DIR> fdopendir(int fd) => libc_shim_fdopendir(fd, errnoPtr);

ffi.Pointer<DIR> opendir(ffi.Pointer<ffi.Char> path) =>
    libc_shim_opendir(path, errnoPtr);

ffi.Pointer<dirent> readdir(ffi.Pointer<DIR> d) =>
    libc_shim_readdir(d, errnoPtr);

extension DirentPtrExtensions on ffi.Pointer<dirent> {
  ffi.Pointer<ffi.Char> get d_name_ptr => libc_shim_d_name_ptr(this);
}
