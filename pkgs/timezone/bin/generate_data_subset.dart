// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:args/args.dart';
import 'package:timezone/standalone.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/tools.dart';


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

  int from = TZDateTime.minMillisecondsSinceEpoch;
  int to = TZDateTime.maxMillisecondsSinceEpoch;;

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
