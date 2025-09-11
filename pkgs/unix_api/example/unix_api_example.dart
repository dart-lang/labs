// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unix_api/unix_api.dart';

void main() {
  print('I am ${getpid()} and my parent is ${getppid()}');
}
