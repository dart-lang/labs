// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:timezone/tzdata.dart' as tzdata;

Uint8List _header(int version, {int leapCount = 2}) {
  final bytes = Uint8List(44);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x545a6966); // TZif
  bytes[4] = version;
  data.setInt32(20, 1); // tzh_ttisgmtcnt
  data.setInt32(24, 1); // tzh_ttisstdcnt
  data.setInt32(28, leapCount);
  data.setInt32(32, 1); // tzh_timecnt
  data.setInt32(36, 1); // tzh_typecnt
  data.setInt32(40, 4); // tzh_charcnt
  return bytes;
}

Uint8List _body({required bool extended}) {
  final timeBytes = extended ? 8 : 4;
  final leapBytes = extended ? 12 : 8;
  final bytes = Uint8List(timeBytes + 1 + 6 + 4 + leapBytes * 2 + 2);
  final data = ByteData.sublistView(bytes);
  if (extended) {
    data.setInt64(0, 0);
  } else {
    data.setInt32(0, 0);
  }
  bytes[timeBytes] = 0; // transition zone index
  final typeOffset = timeBytes + 1;
  data.setInt32(typeOffset, 3600);
  bytes[typeOffset + 4] = 0; // not DST
  bytes[typeOffset + 5] = 0; // abbreviation offset
  bytes.setRange(typeOffset + 6, typeOffset + 10, [84, 83, 84, 0]);
  final leapOffset = typeOffset + 10;
  for (var i = 0; i < 2; i++) {
    if (extended) {
      data.setInt64(leapOffset + i * leapBytes, (i + 1) * 1000);
    } else {
      data.setInt32(leapOffset + i * leapBytes, (i + 1) * 1000);
    }
    data.setInt32(leapOffset + i * leapBytes + timeBytes, i + 1);
  }
  bytes[bytes.length - 2] = 1;
  bytes[bytes.length - 1] = 1;
  return bytes;
}

Uint8List _tzif(int version) {
  final builder = BytesBuilder()
    ..add(_header(version))
    ..add(_body(extended: false));
  if (version != 0) {
    builder
      ..add(_header(version))
      ..add(_body(extended: true))
      ..add([10, 85, 84, 67, 48, 10]); // POSIX tail, ignored by parser
  }
  return builder.takeBytes();
}

void main() {
  for (final version in [0, 50, 51, 52]) {
    test('parses two independent leap records in TZif version $version', () {
      final zone = tzdata.Location.fromBytes('Test/Zone', _tzif(version));
      expect(zone.transitionAt, [0]);
      expect(zone.transitionZone, [0]);
      expect(zone.abbreviations, ['TST']);
      expect(zone.leapAt, [1000, 2000]);
      expect(zone.leapDiff, [1, 2]);
      expect(zone.isStd, [1]);
      expect(zone.isUtc, [1]);
    });
  }

  test('truncated files throw a domain-specific exception', () {
    expect(
      () => tzdata.Location.fromBytes('Test/Zone', [0, 1, 2]),
      throwsA(isA<tzdata.InvalidZoneInfoDataException>()),
    );
    final truncated = _tzif(50).sublist(0, 53);
    expect(
      () => tzdata.Location.fromBytes('Test/Zone', truncated),
      throwsA(isA<tzdata.InvalidZoneInfoDataException>()),
    );
  });

  test('invalid transition zone index is rejected', () {
    final bytes = _tzif(0);
    bytes[44 + 4] = 255;
    expect(
      () => tzdata.Location.fromBytes('Test/Zone', bytes),
      throwsA(isA<tzdata.InvalidZoneInfoDataException>()),
    );
  });

  test('invalid abbreviation offset is rejected', () {
    final bytes = _tzif(0);
    bytes[44 + 4 + 1 + 5] = 255;
    expect(
      () => tzdata.Location.fromBytes('Test/Zone', bytes),
      throwsA(isA<tzdata.InvalidZoneInfoDataException>()),
    );
  });

  test('invalid DST flag is rejected', () {
    final bytes = _tzif(0);
    bytes[44 + 4 + 1 + 4] = 2;
    expect(
      () => tzdata.Location.fromBytes('Test/Zone', bytes),
      throwsA(isA<tzdata.InvalidZoneInfoDataException>()),
    );
  });

  test('unterminated abbreviation is rejected', () {
    final bytes = _tzif(0);
    bytes[44 + 4 + 1 + 6 + 3] = 65;
    expect(
      () => tzdata.Location.fromBytes('Test/Zone', bytes),
      throwsA(isA<tzdata.InvalidZoneInfoDataException>()),
    );
  });
}
