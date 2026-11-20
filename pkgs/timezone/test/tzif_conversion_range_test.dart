// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/src/tools.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/tzdata.dart' as tzdata;

void main() {
  test('conversion preserves the active zones at the DateTime limits', () {
    final loc = tzdata.Location(
      'Test/Zone',
      [-(1 << 62), -(1 << 61), 0, maxTime ~/ 1000 + 1],
      [0, 1, 0, 1],
      ['OLD', 'NEW'],
      [
        const tzdata.TimeZone(0, isDst: false, abbreviationIndex: 0),
        const tzdata.TimeZone(3600, isDst: true, abbreviationIndex: 1),
      ],
      [],
      [],
      [],
      [],
    );
    final converted = tzfileLocationToNativeLocation(loc);
    expect(converted.transitionAt, [minTime, 0]);
    expect(converted.timeZone(minTime).abbreviation, 'NEW');
    expect(converted.timeZone(maxTime).abbreviation, 'OLD');
  });
}
