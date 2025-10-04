// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

/// A container for the address of `errno`.
///
/// Exists so that the memory allocated to store `errno` can be freed when it
/// is no long accessable from Dart code.
///
/// Another approach would be to just track the value of `errno` and create a
/// pointer only as needed. But that would means doing a memory allocation for
/// any POSIX call.
class _Errno implements ffi.Finalizable {
  static final _finalizer = ffi.NativeFinalizer(malloc.nativeFree);
  ffi.Pointer<ffi.Int> errnoPtr;

  _Errno() : errnoPtr = malloc.allocate<ffi.Int>(1) {
    _finalizer.attach(this, errnoPtr.cast());
  }
}

final _errno = _Errno();
ffi.Pointer<ffi.Int> get errnoPtr => _errno.errnoPtr;
