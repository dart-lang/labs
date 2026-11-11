// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:timezone/src/tools.dart';
import 'package:timezone/timezone.dart';

void main() {
  const winter = TimeZone(
    Duration(hours: 2),
    isDst: false,
    abbreviation: 'IST',
  );
  const summer = TimeZone(Duration(hours: 3), isDst: true, abbreviation: 'IDT');
  final march = DateTime.utc(2026, 3, 27).millisecondsSinceEpoch;
  final october = DateTime.utc(2026, 10, 25).millisecondsSinceEpoch;
  final db = LocationDatabase()
    ..add(
      Location('Asia/Jerusalem', [minTime, march, october], [0, 1, 0], [
        winter,
        summer,
      ]),
    )
    ..add(Location('Test/fixed', [], [], [winter]));

  test('range beginning in summer retains summer until autumn transition', () {
    final may = DateTime.utc(2026, 5).millisecondsSinceEpoch;
    final december = DateTime.utc(2026, 12).millisecondsSinceEpoch;
    final filtered = filterTimeZoneData(db, dateFrom: may, dateTo: december);
    final location = filtered.db.get('Asia/Jerusalem');
    expect(location.transitionAt, [minTime, october]);
    expect(location.transitionZone, [1, 0]);
    expect(location.timeZone(may), summer);
    expect(location.timeZone(october - 1), summer);
    expect(location.timeZone(october), winter);
    expect(filtered.report.newTransitionsCount, 2);
    expect(filtered.report.newLocationsCount, 2);
  });

  test('exact transition boundary uses newly active time zone', () {
    final filtered = filterTimeZoneData(db, dateFrom: march, dateTo: march);
    final location = filtered.db.get('Asia/Jerusalem');
    expect(location.transitionAt, [minTime]);
    expect(location.transitionZone, [1]);
    expect(location.timeZone(march), summer);
  });

  test('range before first transition preserves the initial zone', () {
    final future = Location('Test/future', [october], [1], [winter, summer]);
    final source = LocationDatabase()..add(future);
    final filtered = filterTimeZoneData(source, dateFrom: march, dateTo: march);
    final location = filtered.db.get('Test/future');
    expect(location.transitionAt, [minTime]);
    expect(location.transitionZone, [0]);
    expect(location.timeZone(march), winter);
  });

  test('pre-first zone is retained even if first transition is DST', () {
    final source = LocationDatabase()
      ..add(
        Location('Test/summer-first', [march, october], [0, 1], [
          summer,
          winter,
        ]),
      );
    final february = DateTime.utc(2026, 2).millisecondsSinceEpoch;
    final july = DateTime.utc(2026, 7).millisecondsSinceEpoch;
    final original = source.get('Test/summer-first');
    expect(original.timeZone(february), winter);
    final location = filterTimeZoneData(
      source,
      dateFrom: february,
      dateTo: july,
    ).db.get('Test/summer-first');
    expect(location.transitionAt, [minTime, march]);
    expect(location.transitionZone, [1, 0]);
    expect(location.timeZone(february), winter);
    expect(location.timeZone(march), summer);
  });

  test('transitionless locations are included in report', () {
    final filtered = filterTimeZoneData(db, locations: ['Test/fixed']);
    expect(filtered.report.newLocationsCount, 1);
    expect(filtered.report.newTransitionsCount, 0);
    expect(filtered.db.get('Test/fixed').timeZone(march), winter);
  });

  test('rejects reversed date ranges', () {
    expect(
      () => filterTimeZoneData(db, dateFrom: october, dateTo: march),
      throwsArgumentError,
    );
  });
}
