// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:io_file/posix_file_system.dart';

void main() {
  // TODO: Create a better example.
  PosixFileSystem().rename('foo.txt', 'bar.txt');
}
