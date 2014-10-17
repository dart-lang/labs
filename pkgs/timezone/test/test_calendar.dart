import 'package:unittest/unittest.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  final t1 = new DateTime(2014, 11, 17);
  final t2 = new DateTime.fromMillisecondsSinceEpoch(t1.millisecondsSinceEpoch, isUtc: true);

  print(t1);
  print(t1.millisecondsSinceEpoch);
  print(t2);
  print(t2.millisecondsSinceEpoch);
}