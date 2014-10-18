// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:timezone/standalone.dart';

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

void main() {
  initializeTimeZone().then((_) {
    final newLocationDatabase = filterTimeZoneData(LocationDatabase.instance,
        dateFrom: new DateTime.utc(2010, 1, 1).millisecondsSinceEpoch,
        dateTo: new DateTime.utc(2020, 1, 1).millisecondsSinceEpoch);
    /*
    for (final l in newLocationDatabase.locations.values) {
      print(l.name);
      for (final i in l.transitionAt) {
        print('- $i');
      }
    }
     */
    final out = new File('out.tzf');
    out.writeAsBytes(newLocationDatabase.toBytes()).then((_) {
      print('Finished');
    });
  });
}