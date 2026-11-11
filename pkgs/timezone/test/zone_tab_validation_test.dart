// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/tzdata.dart' as tzdata;

void main() {
  test('zone.tab ignores blank and indented comment lines', () {
    final db = tzdata.LocationDescriptionDatabase.fromString(
      '  # comment\n   \nIL\t+3146+03514\tAsia/Jerusalem\n',
    );
    expect(db.locations, hasLength(1));
    expect(db.locations.single.name, 'Asia/Jerusalem');
  });

  for (final line in [
    'IL\tbroken\tAsia/Jerusalem',
    'IL\t+03146+03514\tAsia/Jerusalem',
    'IL\t+3146+3514\tAsia/Jerusalem',
    'IL\t+314601+03514\tAsia/Jerusalem',
    'IL\t+9100+03500\tAsia/Jerusalem',
    'IL\t+3160+03500\tAsia/Jerusalem',
    'IL\t+3159+18100\tAsia/Jerusalem',
    'IL\t+315960+0350000\tAsia/Jerusalem',
    'IL\t+3146+03500',
    'IL',
  ]) {
    test('zone.tab rejects malformed coordinates: $line', () {
      expect(
        () => tzdata.LocationDescription.fromString(line),
        throwsFormatException,
      );
    });
  }
}
