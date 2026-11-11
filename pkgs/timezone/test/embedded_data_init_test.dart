// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as standard;
import 'package:timezone/data/latest_10y.dart' as compact;
import 'package:timezone/data/latest_all.dart' as all;
import 'package:timezone/timezone.dart' as tz;
import '../tool/encode_dart.dart' as generated;

void main() {
  test('Latin-1 encoder produces Uint8List for every byte value', () {
    final source = String.fromCharCodes(List<int>.generate(256, (i) => i));
    final bytes = latin1.encode(source);
    expect(bytes, isA<Uint8List>());
    expect(bytes, List<int>.generate(256, (i) => i));
  });

  test('generated source uses direct Latin-1 conversion', () {
    final generatedSource = generated.generateDartFile(
      name: 'test',
      data: Uint8List.fromList([0, 127, 128, 255]),
      tzVersion: 'test',
    );
    expect(generatedSource, contains("import 'dart:convert'"));
    expect(
      generatedSource,
      contains('initializeDatabase(latin1.encode(_embeddedData))'),
    );
    expect(
      generatedSource,
      isNot(contains('Uint8List.fromList(_embeddedData.codeUnits)')),
    );
  });

  for (final db in <(String, void Function())>[
    ('latest', standard.initializeTimeZones),
    ('latest_all', all.initializeTimeZones),
    ('latest_10y', compact.initializeTimeZones),
  ]) {
    test('${db.$1} round-trips real timezone offset transitions', () {
      db.$2();
      final location = tz.getLocation('Asia/Jerusalem');
      final winter = DateTime.utc(2026, 1, 15).millisecondsSinceEpoch;
      final summer = DateTime.utc(2026, 7, 15).millisecondsSinceEpoch;
      expect(location.timeZone(winter).offset, const Duration(hours: 2));
      expect(location.timeZone(summer).offset, const Duration(hours: 3));
      expect(tz.getLocation('America/New_York').name, 'America/New_York');
    });
  }
}
