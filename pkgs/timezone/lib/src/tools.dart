// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import '../timezone.dart';
import '../tzdata.dart' as tzfile;

const int _maxMillisecondsSinceEpoch = 8640000000000000;
const int _maxSecondsSinceEpoch = 8640000000000;

class FilterReport {
  int originalLocationsCount = 0;
  int originalTransitionsCount = 0;
  int newLocationsCount = 0;
  int newTransitionsCount = 0;
}

class FilteredLocationDatabase {
  final LocationDatabase db;
  final FilterReport report;

  FilteredLocationDatabase(this.db, this.report);
}

FilteredLocationDatabase filterTimeZoneData(
  LocationDatabase db, {
  int dateFrom = TZDateTime.minMillisecondsSinceEpoch,
  int dateTo = TZDateTime.maxMillisecondsSinceEpoch,
  List<String> locations = const [],
}) {
  final report = FilterReport();
  final result = LocationDatabase();

  final locationsSet = HashSet<String>.from(locations);

  report.originalLocationsCount = db.locations.length;

  for (final l in db.locations.values) {
    if (locationsSet.isNotEmpty && !locationsSet.contains(l.name)) {
      continue;
    }

    final transitionsCount = l.transitionAt.length;
    report.originalTransitionsCount += transitionsCount;

    final newTransitionAt = <int>[];
    final newTransitionZone = <int>[];

    if (transitionsCount == 0) {
      result.add(Location(l.name, newTransitionAt, newTransitionZone, l.zones));
      continue;
    }

    var i = 0;

    while (i < transitionsCount && dateFrom > l.transitionAt[i]) {
      i++;
    }

    if (i < transitionsCount) {
      newTransitionAt.add(TZDateTime.minMillisecondsSinceEpoch);
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
      newTransitionAt.add(TZDateTime.minMillisecondsSinceEpoch);
      newTransitionZone.add(l.transitionZone[i - 1]);
    }

    result.add(Location(l.name, newTransitionAt, newTransitionZone, l.zones));
    report.newLocationsCount++;
  }

  return FilteredLocationDatabase(result, report);
}

/// Convert [tzfile.Location] to [Location]
Location tzfileLocationToNativeLocation(tzfile.Location loc) {
  final zones = <TimeZone>[];

  for (final z in loc.zones) {
    zones.add(
      TimeZone(
        Duration(seconds: z.offset),
        isDst: z.isDst,
        abbreviation: loc.abbreviations[z.abbreviationIndex],
      ),
    );
  }

  final transitionAt = <int>[];
  final transitionZone = <int>[];
  int? initialZone;
  for (var i = 0; i < loc.transitionAt.length; i++) {
    final seconds = loc.transitionAt[i];
    if (seconds <= -_maxSecondsSinceEpoch) {
      initialZone = loc.transitionZone[i];
    } else if (seconds <= _maxSecondsSinceEpoch) {
      transitionAt.add(seconds * 1000);
      transitionZone.add(loc.transitionZone[i]);
    } else {
      // Later transitions can influence the fallback before the first one.
      if (initialZone == null) {
        final source = Location(
          loc.name,
          loc.transitionAt,
          loc.transitionZone,
          zones,
        );
        initialZone = zones.indexOf(source.timeZone(-_maxSecondsSinceEpoch));
      }
      break;
    }
  }
  if (initialZone != null) {
    transitionAt.insert(0, -_maxMillisecondsSinceEpoch);
    transitionZone.insert(0, initialZone);
  }
  return Location(loc.name, transitionAt, transitionZone, zones);
}
