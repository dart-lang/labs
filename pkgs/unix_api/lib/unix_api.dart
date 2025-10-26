// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'src/errno.dart';

export 'src/bespoke.dart';
export 'src/constants.g.dart';
export 'src/functions.g.dart';
export 'src/handwritten_constants.dart';

/// The code that indicates the reason for a failed function call.
///
/// See the [POSIX specification for `errno`](https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/errno.h.html).
int get errno => errnoPtr.value;
set errno(int err) => errnoPtr.value = err;
