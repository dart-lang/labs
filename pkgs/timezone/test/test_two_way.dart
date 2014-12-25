import 'package:unittest/unittest.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/standalone.dart';

void main() {
  const timeStep = 15 * 60 * 1000; // 15 minutes
  final startTime = (new DateTime.now().millisecondsSinceEpoch ~/ timeStep) * timeStep;

  initializeTimeZone().then((_) {
    test('Europe/London', () {
      final location = getLocation('Europe/London');
      for (int i = startTime; i >= 0; i -= timeStep) {
        DateTime time1 = new DateTime.fromMillisecondsSinceEpoch(i);

        TZDateTime tzTime1 =
            new TZDateTime(location, time1.year, time1.month, time1.day, time1.hour, time1.minute);

        DateTime localTime2 = tzTime1.toLocal();

        TZDateTime tzTime2 = new TZDateTime.from(localTime2, location);

        expect(tzTime1.toString(), equals(tzTime2.toString()));
      }
    });

    test('America/Detroit', () {
      final location = getLocation('America/Detroit');
      for (int i = startTime; i >= 0; i -= timeStep) {
        DateTime time1 = new DateTime.fromMillisecondsSinceEpoch(i);

        TZDateTime tzTime1 =
            new TZDateTime(location, time1.year, time1.month, time1.day, time1.hour, time1.minute);

        DateTime localTime2 = tzTime1.toLocal();

        TZDateTime tzTime2 = new TZDateTime.from(localTime2, location);

        expect(tzTime1.toString(), equals(tzTime2.toString()));
      }
    });

    test('America/Los_Angeles', () {
      final location = getLocation('America/Los_Angeles');
      for (int i = startTime; i >= 0; i -= timeStep) {
        DateTime time1 = new DateTime.fromMillisecondsSinceEpoch(i);

        TZDateTime tzTime1 =
            new TZDateTime(location, time1.year, time1.month, time1.day, time1.hour, time1.minute);

        DateTime localTime2 = tzTime1.toLocal();

        TZDateTime tzTime2 = new TZDateTime.from(localTime2, location);

        expect(tzTime1.toString(), equals(tzTime2.toString()));
      }
    });

    test('America/New_York', () {
      final location = getLocation('America/New_York');
      for (int i = startTime; i >= 0; i -= timeStep) {
        DateTime time1 = new DateTime.fromMillisecondsSinceEpoch(i);

        TZDateTime tzTime1 =
            new TZDateTime(location, time1.year, time1.month, time1.day, time1.hour, time1.minute);

        DateTime localTime2 = tzTime1.toLocal();

        TZDateTime tzTime2 = new TZDateTime.from(localTime2, location);

        expect(tzTime1.toString(), equals(tzTime2.toString()));
      }
    });
  });
}
