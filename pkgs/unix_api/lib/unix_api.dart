// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'src/libc_bindings.g.dart' as libc;

export 'src/constants.g.dart';
export 'src/libc_bindings.g.dart' hide errno, seterrno;

int get errno => libc.errno();
set errno(int err) => libc.seterrno(err);
