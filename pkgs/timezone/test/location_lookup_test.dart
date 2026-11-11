// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/timezone.dart';

void main() {
  const winter = TimeZone(
    Duration(hours: 2),
    isDst: false,
    abbreviation: 'IST',
  );
  const summer = TimeZone(Duration(hours: 3), isDst: true, abbreviation: 'IDT');

  test('timeZone agrees with lookupTimeZone across transition boundaries', () {
    final first = DateTime.utc(2026, 3, 27).millisecondsSinceEpoch;
    final second = DateTime.utc(2026, 10, 25).millisecondsSinceEpoch;
    final location = Location('test/jerusalem', [first, second], [1, 0], [
      winter,
      summer,
    ]);
    for (final timestamp in [
      minTime,
      first - 1,
      first,
      first + 1,
      second - 1,
      second,
      second + 1,
      maxTime - 1,
    ]) {
      expect(
        location.timeZone(timestamp),
        location.lookupTimeZone(timestamp).timeZone,
        reason: 'timeZone mismatch at $timestamp',
      );
    }
    expect(location.timeZone(first - 1), winter);
    expect(location.timeZone(first), summer);
    expect(location.timeZone(second), winter);
  });

  test('timeZone honors overrides of lookupTimeZone', () {
    expect(_CustomLocation(winter).timeZone(0), winter);
  });

  test('pre-transition lookups see changes to the supplied zones', () {
    final zones = [winter];
    final location = Location('test/mutable', [], [], zones);
    expect(location.timeZone(0), winter);
    zones[0] = summer;
    expect(location.timeZone(0), summer);
    expect(location.lookupTimeZone(0).timeZone, summer);
  });

  test('cached current interval matches its exact transition boundaries', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    final location = Location(
      'test/current',
      [now - 60000, now + 60000],
      [0, 1],
      [winter, summer],
    );
    expect(location.timeZone(now), winter);
    expect(location.lookupTimeZone(now).start, now - 60000);
    expect(location.lookupTimeZone(now).end, now + 60000);
    expect(location.timeZone(now + 60000), summer);
  });

  test(
    'pre-first and transitionless locations preserve their initial zone',
    () {
      final later = DateTime.utc(2035).millisecondsSinceEpoch;
      final beforeFirst = Location('test/pre-first', [later], [1], [
        winter,
        summer,
      ]);
      expect(beforeFirst.timeZone(later - 1), winter);
      expect(beforeFirst.lookupTimeZone(later - 1).timeZone, winter);
      expect(beforeFirst.timeZone(later), summer);

      final fixed = Location('test/fixed', [], [], [winter]);
      expect(fixed.timeZone(0), winter);
      expect(fixed.lookupTimeZone(0).timeZone, winter);
      final empty = Location('test/empty', [], [], []);
      expect(empty.timeZone(0), TimeZone.UTC);
      expect(empty.lookupTimeZone(0).timeZone, TimeZone.UTC);
    },
  );
}

class _CustomLocation extends Location {
  _CustomLocation(this.zone) : super('test/custom', [], [], []);
  final TimeZone zone;

  @override
  TzInstant lookupTimeZone(int millisecondsSinceEpoch) =>
      TzInstant(zone, minTime, maxTime);
}
