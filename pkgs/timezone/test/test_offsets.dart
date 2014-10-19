import 'package:unittest/unittest.dart';
import 'package:timezone/standalone.dart' as tz;

void main() {
  tz.initializeTimeZone()
  .then((_) {
    group('UTC to America/Detroit', () {
      final detroit = tz.getLocation('America/Detroit');

      group('Simple translations', () {
        final u1 = new DateTime.utc(1975, 01, 01, 5);
        final x1 = new tz.TZDateTime.from(detroit, u1);

        test('$u1 => 1975-01-01 00:00:00.000-0500', () {
          expect(x1.toString(), equals('1975-01-01 00:00:00.000-0500'));
        });

        final u2 = u1.subtract(const Duration(milliseconds: 1));
        final x2 = new tz.TZDateTime.from(detroit, u2);

        test('$u2 => 1974-12-31 23:59:59.999-0500', () {
          expect(x2.toString(), equals('1974-12-31 23:59:59.999-0500'));
        });

        final u3 = u1.add(const Duration(milliseconds: 1));
        final x3 = new tz.TZDateTime.from(detroit, u3);

        test('$u3 => 1975-01-01 00:00:00.001-0500', () {
          expect(x3.toString(), equals('1975-01-01 00:00:00.001-0500'));
        });
      });

      group('EWT/EPT boundaries', () {
        final u1 = new DateTime.utc(1945, 09, 30, 6);
        final x1 = new tz.TZDateTime.from(detroit, u1);

        test('$u1 => 1945-09-30 01:00:00.000-0500', () {
          expect(x1.toString(), '1945-09-30 01:00:00.000-0500');
        });

        final u2 = u1.subtract(const Duration(milliseconds: 1));
        final x2 = new tz.TZDateTime.from(detroit, u2);

        test('$u2 => 1945-09-30 01:59:59.999-0400', () {
          expect(x2.toString(), equals('1945-09-30 01:59:59.999-0400'));
        });

        final u3 = u1.add(const Duration(milliseconds: 1));
        final x3 = new tz.TZDateTime.from(detroit, u3);

        test('$u3 => 1945-09-30 01:00:00.001-0500', () {
          expect(x3.toString(), equals('1945-09-30 01:00:00.001-0500'));
        });
      });
    });
  });
}