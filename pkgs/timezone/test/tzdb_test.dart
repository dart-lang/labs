import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/src/tzdb.dart';
import 'package:timezone/timezone.dart';

void main() {
  group('tzdbDeserialize validation', () {
    test('throws FormatException on truncated chunk header', () {
      final data = [1, 2, 3]; // less than 8 bytes
      expect(
        () => tzdbDeserialize(data).toList(),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when chunk length is not 8-byte aligned', () {
      final data = Uint8List(16);
      ByteData.sublistView(data).setUint32(0, 5); // 5 is not divisible by 8
      expect(
        () => tzdbDeserialize(data).toList(),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when chunk length exceeds buffer size', () {
      final data = Uint8List(8);
      ByteData.sublistView(data).setUint32(0, 96); // 96 > buffer size remaining
      expect(
        () => tzdbDeserialize(data).toList(),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'throws FormatException when location chunk is smaller than 32 bytes',
      () {
        final data = Uint8List(16);
        ByteData.sublistView(data).setUint32(0, 8); // chunk length = 8 bytes
        expect(
          () => tzdbDeserialize(data).toList(),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('throws FormatException on out-of-bounds section offsets', () {
      final data = Uint8List(40);
      final bdata = ByteData.sublistView(data);
      bdata.setUint32(0, 32); // chunk length = 32
      // Set zonesOffset (at header offset 16) to an out-of-bounds value
      bdata.setUint32(24, 0x70000000); // zonesOffset = 0x70000000

      expect(
        () => tzdbDeserialize(data).toList(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('tzdbDeserialize rejects corrupted location data', () {
    final sample = LocationDatabase()
      ..add(
        Location('Test/Zone', [123000], [0], [
          const TimeZone(Duration(hours: 2), isDst: false, abbreviation: 'TZ'),
        ]),
      );

    // Each serialized location is preceded by an 8-byte chunk header.
    const chunk = 8;
    Uint8List encoded() => Uint8List.fromList(tzdbSerialize(sample));
    int header(Uint8List bytes, int field) =>
        ByteData.sublistView(bytes).getUint32(chunk + field);
    Matcher throwsFormat(String message) => throwsA(
      isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains(message),
      ),
    );

    test('invalid zone abbreviation indices', () {
      final bytes = encoded();
      bytes[chunk + header(bytes, 16) + 5] = 255;
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('invalid zone entry'),
      );
    });

    test('invalid transition zone indices', () {
      final bytes = encoded();
      bytes[chunk + header(bytes, 24) + 8] = 255;
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('invalid transition zone'),
      );
    });

    test('invalid daylight-saving flags', () {
      final bytes = encoded();
      bytes[chunk + header(bytes, 16) + 4] = 2;
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('invalid zone entry'),
      );
    });

    for (final seconds in [
      double.nan,
      double.infinity,
      -8640000000001.0,
      8640000000001.0,
    ]) {
      test('transition timestamp $seconds', () {
        final bytes = encoded();
        ByteData.sublistView(
          bytes,
        ).setFloat64(chunk + header(bytes, 24), seconds);
        expect(
          () => tzdbDeserialize(bytes).toList(),
          throwsFormat('invalid transition at index 0'),
        );
      });
    }

    test('out-of-order transition times', () {
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
      ByteData.sublistView(bytes).setFloat64(chunk + header(bytes, 24) + 8, 99);
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('out-of-order or fractional'),
      );
    });

    test('fractional transition timestamps', () {
      final bytes = encoded();
      ByteData.sublistView(bytes).setFloat64(chunk + header(bytes, 24), 123.5);
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('out-of-order or fractional'),
      );
    });

    test('sections that overlap earlier data', () {
      final bytes = encoded();
      ByteData.sublistView(bytes).setUint32(chunk + 16, 32);
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('invalid section layout'),
      );
    });

    test('misaligned zones section', () {
      final bytes = encoded();
      final zonesOffset = header(bytes, 16);
      expect(zonesOffset % 4, 0);
      ByteData.sublistView(bytes).setUint32(chunk + 16, zonesOffset + 1);
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('invalid section layout'),
      );
    });

    test('misaligned transitions section', () {
      final bytes = encoded();
      final transitionsOffset = header(bytes, 24);
      expect(transitionsOffset % 8, 0);
      ByteData.sublistView(bytes).setUint32(chunk + 24, transitionsOffset + 4);
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('invalid section layout'),
      );
    });

    test('non-ASCII location names', () {
      final bytes = encoded();
      bytes[chunk + header(bytes, 0)] = 0xC3;
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('non-ASCII text'),
      );
    });

    test('non-ASCII abbreviations', () {
      final bytes = encoded();
      bytes[chunk + header(bytes, 8)] = 0xC3;
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('non-ASCII text'),
      );
    });

    test('unterminated abbreviation data', () {
      final bytes = encoded();
      final end = header(bytes, 8) + header(bytes, 12);
      bytes[chunk + end - 1] = 65;
      expect(
        () => tzdbDeserialize(bytes).toList(),
        throwsFormat('unterminated abbreviation'),
      );
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
  });

  test('tzdbDeserialize preserves transitions rounded to the same second', () {
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
}
