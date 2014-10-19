// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// Look at https://bitbucket.org/pellepim/jstimezonedetect and
/// https://github.com/google/closure-library/blob/03b4b6894b304c9a6e1abac8725d95a02e3bb635/closure/goog/locale/timezonedetection.js
/// for the possible better solution.
part of timezone;

/// Function to detect local [Location]
///
/// Detection algorithm works by applying different filters to the current
/// [TimeZone]s in all [Location]s until we don't have any ambiguities.
///
/// Filters:
/// * by timezone offset
/// * by abbreviation
Location detectLocalLocation() {
  var locations = [];
  for (final loc in LocationDatabase.instance.locations.values) {
    locations.add(new Tuple2(loc, loc.currentTimeZone));
  }

  final now = new DateTime.now();
  final timeZoneOffset = now.timeZoneOffset.inMilliseconds;
  final timeZoneName = now.timeZoneName;

  bool offsetFilter(Tuple2<Location, TimeZone> t) {
    return timeZoneOffset == t.i2.offset ? true : false;
  }

  bool abbrFilter(Tuple2<Location, TimeZone> t) {
    return timeZoneName == t.i2.abbr ? true : false;
  }

  final filters = [offsetFilter, abbrFilter];

  var i = 0;
  while (i < filters.length && locations.isNotEmpty && locations.length > 1) {
    locations.retainWhere(filters[i++]);
  }

  // TODO: fix this with something better.
  if (locations.isEmpty) {
    return null;
  }

  return locations.first.i1;
}
