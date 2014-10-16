// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

library timezone.server;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as ospath;
import 'package:timezone/timezone.dart';

export 'package:timezone/timezone.dart' show Location, TimeZone, translateTime;

/// Path to the package root directory
final _packageRoot = Platform.packageRoot.isEmpty ?
    ospath.join(ospath.dirname(Platform.script.path), 'packages') :
    Platform.packageRoot;

/// Path to the TimeZone data file
final _dataPath =
    ospath.join(_packageRoot, 'timezone', 'data', dataDefaultFilename);

/// Initialize global Time Zone database.
///
/// ```dart
/// import 'package:timezone/server.dart' as tz;
///
/// tz.initializeTimeZone()
/// .then(() {
///
///   final now = new DateTime.now().millisecondsSinceEpoch;
///   final nowEastern = tz.translateTime(now, 'US/Eastern');
///
/// });
/// ```
Future initializeTimeZone() {
  return new File(_dataPath).readAsBytes().then((rawData) {
    timeZones = new LocationDatabase.fromBytes(rawData);
  });
}
