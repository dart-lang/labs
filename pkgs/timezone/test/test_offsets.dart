import 'package:unittest/unittest.dart';
import 'package:timezone/server.dart' as tz;

void main() {
  tz.initializeTimeZone()
  .then((_) {
    group('UTC to America/Detroit', () {
      group('Simple translations', () {
        final o = new DateTime.utc(1975, 01, 01, 5);

        test('1975-01-01 05:00', () {
          final r = tz.translateTime(o.millisecondsSinceEpoch, 'America/Detroit');
          expect(r, equals(157766400000));
        });

        test('1975-01-01 05:00 minus 1 ms', () {
          final t = o.subtract(const Duration(milliseconds: 1));
          final r = tz.translateTime(t.millisecondsSinceEpoch, 'America/Detroit');
          expect(r, equals(157766399999));
        });

        test('1975-01-01 05:00 plus 1 ms', () {
          final t = o.add(const Duration(milliseconds: 1));
          final r = tz.translateTime(t.millisecondsSinceEpoch, 'America/Detroit');
          expect(r, equals(157766400001));
        });
      });
      group('EWT/EPT boundaries', () {
        final o1 = new DateTime.utc(1945, 09, 30, 2);
        final o2 = new DateTime.utc(1945, 09, 30, 6);

        test('1945-09-30 01:59', () {
          final t = o1.subtract(const Duration(seconds: 1));
          final r = tz.translateTime(t.millisecondsSinceEpoch, 'America/Detroit');
          expect(r, equals(-765424801000));
        });

        test('1945-09-30 02:00', () {
          final r = tz.translateTime(o1.millisecondsSinceEpoch, 'America/Detroit');
          expect(r, equals(-765424800000));
        });

        test('1945-09-30 06:00', () {
          final r = tz.translateTime(o2.millisecondsSinceEpoch, 'America/Detroit');
          expect(r, equals(-765414000000));
        });

        test('1945-09-30 06:00 minus 1 ms', () {
          final t = o2.subtract(const Duration(milliseconds: 1));
          final r = tz.translateTime(t.millisecondsSinceEpoch, 'America/Detroit');
          expect(r, equals(-765410400001));
        });

        test('1945-09-30 06:00 plus 1 ms', () {
          final t = o2.add(const Duration(milliseconds: 1));
          final r = tz.translateTime(t.millisecondsSinceEpoch, 'America/Detroit');
          expect(r, equals(-765413999999));
        });
      });
    });
  });
}