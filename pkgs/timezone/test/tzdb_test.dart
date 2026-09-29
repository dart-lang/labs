@TestOn('vm')
library;

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:timezone/src/tzdb.dart';

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
}
