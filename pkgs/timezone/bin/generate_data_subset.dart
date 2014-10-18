// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:args/args.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';

/// Maximum value for time instants.
const int _omega = 8640000000000000;

/// Minimum value for time instants.
const int _alpha = -_omega;

LocationDatabase filterTimeZoneData(LocationDatabase db, {int dateFrom: _alpha,
    int dateTo: _omega}) {
  final result = new LocationDatabase();

  for (final l in db.locations.values) {
    final transitionsCount = l.transitionAt.length;
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

      while (i < transitionsCount && l.transitionAt[i] <= dateTo) {
        newTransitionAt.add(l.transitionAt[i]);
        newTransitionZone.add(l.transitionZone[i]);
        i++;
      }
    } else {
      newTransitionAt.add(_alpha);
      newTransitionZone.add(l.transitionZone[i - 1]);
    }

    result.add(
        new Location(l.name, newTransitionAt, newTransitionZone, l.zones));
  }

  return result;
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
    final newLocationDatabase = filterTimeZoneData(LocationDatabase.instance,
        dateFrom: from,
        dateTo: to);

    return new File(output).writeAsBytes(newLocationDatabase.toBytes()).then((_) {
      print('Finished');
      exit(0);
    });

  }).catchError((e) {
    print(e);
    exit(1);
  });
}