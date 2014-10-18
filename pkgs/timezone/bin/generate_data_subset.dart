// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:args/args.dart';
import 'package:tuple/tuple.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

class Report {
  int originalLocationsCount = 0;
  int originalTransitionsCount = 0;
  int newLocationsCount = 0;
  int newTransitionsCount = 0;
}

/// Maximum value for time instants.
const int _omega = 8640000000000000;

/// Minimum value for time instants.
const int _alpha = -_omega;

Tuple2<LocationDatabase, Report> filterTimeZoneData(LocationDatabase db,
    {int dateFrom: _alpha, int dateTo: _omega}) {
  final report = new Report();
  final result = new LocationDatabase();

  report.originalLocationsCount = db.locations.length;

  for (final l in db.locations.values) {
    final transitionsCount = l.transitionAt.length;
    report.originalTransitionsCount += transitionsCount;

    final newTransitionAt = [];
    final newTransitionZone = [];

    if (transitionsCount == 0) {
      result.add(
          new Location(l.name, newTransitionAt, newTransitionZone, l.zones));
      continue;
    }

    var i = 0;

    while (i < transitionsCount && dateFrom > l.transitionAt[i]) {
      i++;
    }

    if (i < transitionsCount) {
      newTransitionAt.add(_alpha);
      newTransitionZone.add(l.transitionZone[i]);
      i++;
      report.newTransitionsCount++;

      while (i < transitionsCount && l.transitionAt[i] <= dateTo) {
        newTransitionAt.add(l.transitionAt[i]);
        newTransitionZone.add(l.transitionZone[i]);
        i++;
        report.newTransitionsCount++;
      }
    } else {
      newTransitionAt.add(_alpha);
      newTransitionZone.add(l.transitionZone[i - 1]);
    }

    result.add(
        new Location(l.name, newTransitionAt, newTransitionZone, l.zones));
    report.newLocationsCount++;
  }

  return new Tuple2(result, report);
}

void main(List<String> arguments) {
  // Parse CLI arguments
  final parser = new ArgParser()
  ..addOption('source', abbr: 's', defaultsTo: 'packages/timezone/data/$dataDefaultFilename')
  ..addOption('output', abbr: 'o')
  ..addOption('from', abbr: 'f')
  ..addOption('to', abbr: 't');

  final argResults = parser.parse(arguments);

  final String source = argResults['source'];
  final String output = argResults['output'];

  if (source.isEmpty || output == null || output.isEmpty) {
    print(parser.getUsage());
    exit(64);
  }

  int from = _alpha;
  int to = _omega;

  final String argFrom = argResults['from'];
  final String argTo = argResults['to'];

  if (argResults['from'] != null) {
    try {
      from = DateTime.parse(argFrom).millisecondsSinceEpoch;
    } catch (e) {
      print(e.toString());
      exit(66);
    }
  }
  if (argResults['to'] != null) {
    try {
      to = DateTime.parse(argTo).millisecondsSinceEpoch;
    } catch (e) {
      print(e.toString());
      exit(66);
    }
  }

  initializeTimeZone(source).then((_) {
    final result = filterTimeZoneData(LocationDatabase.instance,
        dateFrom: from,
        dateTo: to);

    final newDB = result.i1;
    final report = result.i2;

    return new File(output).writeAsBytes(newDB.toBytes()).then((_) {
      print('Locations: ${report.originalLocationsCount} => ${report.newLocationsCount}');
      print('Transitions: ${report.originalTransitionsCount} => ${report.newTransitionsCount}');
      exit(0);
    });

  }).catchError((e) {
    print(e);
    exit(1);
  });
}
