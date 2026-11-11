// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/src/tzdb.dart';
import 'package:timezone/timezone.dart';

void main() {
  final sample = LocationDatabase()
    ..add(
      Location('Test/Zone', [123000], [0], [
        const TimeZone(Duration(hours: 2), isDst: false, abbreviation: 'TZ'),
      ]),
    );

  Uint8List encoded() => Uint8List.fromList(tzdbSerialize(sample));

  group('corrupted binary timezone data', () {
    test('rejects invalid zone abbreviation indices', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final zonesOffset = data.getUint32(8 + 16);
      bytes[8 + zonesOffset + 5] = 255;
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects invalid transition zone indices', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final transitionsOffset = data.getUint32(8 + 24);
      bytes[8 + transitionsOffset + 8] = 255;
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects invalid daylight-saving flags', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final zonesOffset = data.getUint32(8 + 16);
      bytes[8 + zonesOffset + 4] = 2;
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects non-finite transition timestamps', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final transitionsOffset = data.getUint32(8 + 24);
      data.setFloat64(8 + transitionsOffset, double.nan);
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects out-of-order transition times', () {
      final sequential = LocationDatabase()
        ..add(
          Location('Test/Two', [100000, 200000], [0, 0], [
            const TimeZone(
              Duration(hours: 2),
              isDst: false,
              abbreviation: 'TZ',
            ),
          ]),
        );
      final bytes = Uint8List.fromList(tzdbSerialize(sequential));
      final data = ByteData.sublistView(bytes);
      final offset = data.getUint32(8 + 24);
      data.setFloat64(8 + offset + 8, 99);
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects fractional transition timestamps', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final offset = data.getUint32(8 + 24);
      data.setFloat64(8 + offset, 123.5);
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects sections that overlap earlier data', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      data.setUint32(8 + 16, 32);
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });

    test('rejects unterminated abbreviation data', () {
      final bytes = encoded();
      final data = ByteData.sublistView(bytes);
      final offset = data.getUint32(8 + 8);
      final length = data.getUint32(8 + 12);
      bytes[8 + offset + length - 1] = 65;
      expect(() => tzdbDeserialize(bytes).toList(), throwsFormatException);
    });
  });

  test('preserves transitions rounded to the same second', () {
    final db = LocationDatabase()
      ..add(
        Location('Test/Rounded', [1000, 1999], [0, 1], [
          TimeZone.UTC,
          const TimeZone(Duration(hours: 1), isDst: true, abbreviation: 'DST'),
        ]),
      );
    final location = tzdbDeserialize(tzdbSerialize(db)).single;
    expect(location.transitionAt, [1000, 1000]);
    expect(location.timeZone(1000).abbreviation, 'DST');
  });

  test(
    'failed initialization preserves the previous database and local zone',
    () {
      tz_data.initializeTimeZones();
      final before = getLocation('America/Detroit');
      setLocalLocation(before);
      final broken = [...encoded(), 1, 2, 3]; // Truncated second chunk.
      try {
        expect(() => initializeDatabase(broken), throwsFormatException);
        expect(identical(getLocation('America/Detroit'), before), isTrue);
        expect(identical(local, before), isTrue);
      } finally {
        tz_data.initializeTimeZones();
      }
    },
  );
}
