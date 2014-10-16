// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

library timezone.browser;

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'package:timezone/timezone.dart';

export 'package:timezone/timezone.dart' show Location, TimeZone, translateTime;

/// Initialize global Time Zone database.
///
/// ```dart
/// import 'package:timezone/browser.dart' as tz;
///
/// tz.initializeTimeZone()
/// .then(() {
///
///   final now = new DateTime.now().millisecondsSinceEpoch;
///   final nowEastern = tz.translateTime(now, 'US/Eastern');
///
/// });
/// ```
Future initializeTimeZone([String url =
    '/packages/timezone/data/$dataDefaultFilename']) {
  return HttpRequest.request(
      url,
      method: 'GET',
      responseType: 'arraybuffer',
      mimeType: 'application/octet-stream').then((req) {
    final response = req.response;
    if (response is ByteBuffer) {
      timeZones = new LocationDatabase.fromBytes(response.asUint8List());
    }
  });
}
