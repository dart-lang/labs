// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// TimeZone library
library timezone;

import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';
import 'package:tuple/tuple.dart';

part 'package:timezone/src/location.dart';
part 'package:timezone/src/location_database.dart';
part 'package:timezone/src/exceptions.dart';
part 'package:timezone/src/datetime.dart';

/// Latest version of the Time Zone database.
const String dataLatestVersion = '2014h';

/// Time Zone data file extension.
const String dataExtension = 'tzf';

/// Default file name for Time Zone data file.
const String dataDefaultFilename = '$dataLatestVersion.$dataExtension';

/// Reference to the current [LocationDatabase]
LocationDatabase timeZones;

/// translate instant in time expressed as milliseconds since
/// January 1, 1970 00:00:00 UTC.
///
/// ```dart
/// final now = new DateTime.now().millisecondsSinceEpoch;
/// final nowInDetroit = translateTime(now, 'America/Detroit');
/// ```
int translateTime(int millisecondsSinceEpoch, String locationName) {
  final loc = timeZones.get(locationName);
  return loc.translate(millisecondsSinceEpoch);
}

/// Find [Location] by its name.
///
/// ```dart
/// final detroit = getLocation('America/Detroit');
/// ```
Location getLocation(String locationName) {
  return timeZones.get(locationName);
}