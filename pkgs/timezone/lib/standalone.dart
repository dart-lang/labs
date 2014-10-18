// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

library timezone.standalone;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as ospath;
import 'package:timezone/timezone.dart';

export 'package:timezone/timezone.dart' show LocationDatabase, Location,
    TimeZone, translateTime, getLocation, TZDateTime;

/// Load file
Future<List<int>> loadAsBytes(String path) {
  final script = Platform.script;
  final scheme = Platform.script.scheme;

  if (scheme.startsWith('http')) {
    return new HttpClient().getUrl(
        new Uri(
            scheme: script.scheme,
            host: script.host,
            port: script.port,
            path: 'packages/' + path)).then((req) {
      return req.close();
    }).then((response) {
      return response.fold(
          new BytesBuilder(),
          (b, d) => b..add(d)).then((builder) {
        return builder.takeBytes();
      });
    });
  } else if (scheme == 'file') {
    return new File(
        ospath.join(ospath.dirname(script.path), 'packages', path)).readAsBytes();
  }

  // TODO: fix this
  throw new Exception('Error');
}

/// Initialize Time Zone database.
///
/// ```dart
/// import 'package:timezone/standalone.dart' as tz;
///
/// tz.initializeTimeZone()
/// .then(() {
///   final eastern = tz.getLocation('US/Eastern');
/// });
/// ```
Future initializeTimeZone() {
  return loadAsBytes('timezone/data/$dataDefaultFilename').then((rawData) {
    LocationDatabase.initialize(rawData);
  }).catchError((e) {
    // TODO: fix this
    throw new TimeZoneInitializationException('failed');
  });
}
