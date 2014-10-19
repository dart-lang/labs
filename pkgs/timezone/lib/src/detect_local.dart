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
