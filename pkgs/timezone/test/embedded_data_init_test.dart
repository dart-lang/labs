// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as standard;
import 'package:timezone/data/latest_10y.dart' as compact;
import 'package:timezone/data/latest_all.dart' as all;
import 'package:timezone/src/tzdb.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  for (final (variant, initializeTimeZones) in <(String, void Function())>[
    ('latest', standard.initializeTimeZones),
    ('latest_all', all.initializeTimeZones),
    ('latest_10y', compact.initializeTimeZones),
  ]) {
    test('$variant.dart embeds the same locations as $variant.tzf', () async {
      final packageUri = Uri(scheme: 'package', path: 'timezone/timezone.dart');
      final libPath = p.dirname(
        (await Isolate.resolvePackageUri(packageUri))!.toFilePath(),
      );
      final expected = tzdbDeserialize(
        await File(p.join(libPath, 'data', '$variant.tzf')).readAsBytes(),
      ).toList();

      initializeTimeZones();
      final actual = tz.timeZoneDatabase.locations;

      expect(expected, isNotEmpty);
      expect(actual.keys, unorderedEquals(expected.map((l) => l.name)));
      // Location.== compares only the name, so check the contents directly.
      for (final location in expected) {
        final embedded = actual[location.name]!;
        expect(
          embedded.transitionAt,
          location.transitionAt,
          reason: location.name,
        );
        expect(
          embedded.transitionZone,
          location.transitionZone,
          reason: location.name,
        );
        expect(embedded.zones, location.zones, reason: location.name);
      }
    });
  }
}
