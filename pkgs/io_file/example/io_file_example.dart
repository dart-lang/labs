// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:io_file/io_file.dart';
import 'package:io_file/windows_file_system.dart';

import 'package:path/path.dart' as p;

bool isHidden(String path) {
  if (fileSystem case final WindowsFileSystem fs) {
    return fs.metadata(path).isHidden;
  } else {
    // On POSIX, convention is that files starting with a period are hidden
    // (except for the special files representing the current working directory
    // and parent directory).
    final name = p.basename(path);
    return name.startsWith('.') && name != '.' && name != '..';
  }
}

void main() {
  isHidden('somefile');
}
