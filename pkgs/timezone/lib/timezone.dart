// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// # TimeZone library
///
/// Time zone database and time zone aware DateTime.
library timezone;

import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';
import 'package:tuple/tuple.dart';

part 'package:timezone/src/location.dart';
part 'package:timezone/src/location_database.dart';
part 'package:timezone/src/exceptions.dart';
part 'package:timezone/src/date_time.dart';
part 'package:timezone/src/detect_local.dart';

/// Latest version of the Time Zone database.
const String tzDataLatestVersion = '2014h';

/// Time Zone database file extension.
const String tzDataExtension = 'tzf';

/// File name of the Time Zone default database.
const String tzDataDefaultFilename = '$tzDataLatestVersion.$tzDataExtension';

/// Path to the Time Zone default database.
const String tzDataDefaultPath = 'packages/timezone/data/$tzDataDefaultFilename';

LocationDatabase _database;
Location _UTC;
Location _local;

/// Global TimeZone database
LocationDatabase get timeZoneDatabase => _database;

/// UTC Location
Location get UTC => _UTC;

/// Local Location
Location get local => _local;

/// Find [Location] by its name.
///
/// ```dart
/// final detroit = getLocation('America/Detroit');
/// ```
Location getLocation(String locationName) {
  return _database.get(locationName);
}

/// Set local [Location]
///
/// ```dart
/// final detroit = getLocation('America/Detroit')
/// setLocalLocation(detroit);
/// ```
void setLocalLocation(Location location) {
  _local = location;
}

/// Initialize Time zone database.
void initializeDatabase(List<int> rawData) {
  _database = new LocationDatabase.fromBytes(rawData);

  if (_UTC == null) {
    _UTC = new Location('UTC', [_alpha], [0], [const TimeZone(0, false, 'UTC')]);
  }

  if (_local == null) {
    _local = detectLocalLocation();
  }
}
