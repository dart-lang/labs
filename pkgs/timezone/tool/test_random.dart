/// Run random tests against `date(1)` unix command

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';

import 'package:timezone/server.dart';

int minEpochTime = new DateTime.utc(1890).millisecondsSinceEpoch ~/ 1000;
int maxEpochTime = new DateTime.utc(2020).millisecondsSinceEpoch ~/ 1000;

Future<String> dateCmd(int time, String tz) {
  return Process.run(
      'date',
      ['-d', '@$time', '+%Y-%m-%d %H:%M:%S'],
      environment: {
    'TZ': tz
  }).then((r) {
    return r.stdout;
  });
}

void main(List<String> arguments) {
  // Parse CLI arguments
  final parser =
      new ArgParser()..addOption('iterations', abbr: 'i', defaultsTo: '1000');
  final argResults = parser.parse(arguments);

  final mr = maxEpochTime - minEpochTime;
  final min = minEpochTime;

  var seed = 0;
  var r = new Random(seed);
  var i = int.parse(argResults['iterations']);

  print('Seed: $seed');
  print('Iterations: $i');

  initializeTimeZone().then((_) {
    final zoneNames =
        LocationDatabase.instance.locations.keys.map((k) => k).toList();
    final zoneCount = zoneNames.length;

    Future.doWhile(() {
      final time = r.nextInt(mr) + min;
      final tz = zoneNames[r.nextInt(zoneCount)];

      return dateCmd(time, tz).then((v) {
        final x =
            new TZDateTime.fromMillisecondsSinceEpoch(getLocation(tz), time * 1000);
        v = v.trim();

        if (v != x.toString().substring(0, 19)) {
          print('Error: $tz $time $x != $v');
        }

        i--;
        return i == 0 ? false : true;
      });

    });
  });
}
