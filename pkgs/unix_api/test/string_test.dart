// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:ffi/ffi.dart' as ffi;
import 'package:unix_api/unix_api.dart';
import 'package:test/test.dart';

void main() {
  group('string', () {
    test('strerror', () {
      expect(
        strerror(ENOTDIR).cast<ffi.Utf8>().toDartString(),
        'Not a directory',
      );
    });
  });
}
