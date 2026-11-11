// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/standalone.dart' as standalone;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test(
    'standalone can load packaged tzdb and resolve known locations',
    () async {
      await standalone.initializeTimeZone();
      expect(standalone.getLocation('Asia/Jerusalem').name, 'Asia/Jerusalem');
    },
  );

  test('missing timezone data reports TimeZoneInitException', () async {
    await standalone.initializeTimeZone();
    final known = tz.getLocation('America/Detroit');
    await expectLater(
      standalone.initializeTimeZone('data/nonexistent-tzdata-20261111.tzf'),
      throwsA(isA<tz.TimeZoneInitException>()),
    );
    expect(identical(tz.getLocation('America/Detroit'), known), isTrue);
  });
}
