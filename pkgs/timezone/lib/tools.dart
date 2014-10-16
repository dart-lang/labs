// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

library timezone.tools;

import 'package:timezone/tzfile.dart' as tzfile;
import 'package:timezone/timezone.dart';

const int _maxMillisecondsSinceEpoch = 8640000000000000;
const int _maxSecondsSinceEpoch = 8640000000000;

/// Convert [tzfile.Location] to [Location]
Location tzfileLocationToNativeLocation(tzfile.Location loc) {
// convert to milliseconds
  final transitionAt = loc.transitionAt.map(
      (i) =>
          (i < -_maxSecondsSinceEpoch) ? -_maxMillisecondsSinceEpoch : i * 1000).toList();

  final zones = [];

  for (final z in loc.zones) {
    zones.add(new TimeZone(z.offset * 1000, z.isDst, loc.abbrs[z.abbrIndex]));
  }

  return new Location(loc.name, transitionAt, loc.transitionZone, zones);
}
