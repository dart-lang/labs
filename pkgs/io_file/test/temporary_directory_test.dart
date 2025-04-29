// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('posix')
library;

import 'package:io_file/io_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('temporaryDirectory', () {
    test('success', () {
      final tmp = fileSystem.temporaryDirectory;
      expect(p.isAbsolute(tmp), isTrue);
    });
  });
}
