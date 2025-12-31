// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:integration_test/integration_test.dart';
import '../../test/read_as_bytes_test.dart' as read_as_bytes;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TODO(brianquinlan): Enable more tests.
  read_as_bytes.main();
}
