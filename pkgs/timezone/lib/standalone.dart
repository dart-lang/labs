// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// TimeZone initialization for standalone environments.
///
/// ```dart
/// import 'package:timezone/standalone.dart';
///
/// initializeTimeZone().then((_) {
///  final detroit = getLocation('America/Detroit');
///  final now = TZDateTime.now(detroit);
/// });
/// ```
library;

import 'dart:io' hide BytesBuilder;
import 'dart:isolate';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'timezone.dart';

export 'package:timezone/timezone.dart'
    show
        Location,
        TZDateTime,
        TimeZone,
        getLocation,
        setLocalLocation,
        timeZoneDatabase;

final String tzDataDefaultPath = p.join('data', tzDataDefaultFilename);

// Load file
Future<List<int>> _loadAsBytes(String path) async {
  final script = Platform.script;
  final scheme = script.scheme;

  if (scheme == 'http' || scheme == 'https') {
    // Preserve support for Dart scripts loaded over HTTP while closing the
    // underlying client even if the request, response or decoding fails.
    final client = HttpClient();
    try {
      final uri = Uri(
        scheme: scheme,
        host: script.host,
        port: script.port,
        path: path,
      );
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'Timezone database request returned HTTP ${response.statusCode}',
          uri: uri,
        );
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  final uri = await Isolate.resolvePackageUri(
    Uri(scheme: 'package', path: 'timezone/$path'),
  );
  if (uri == null) {
    throw FileSystemException('Cannot resolve timezone package data URI', path);
  }
  return File(p.fromUri(uri)).readAsBytes();
}

/// Initialize Time Zone database.
///
/// Throws [TimeZoneInitException] when something is wrong.
///
/// ```dart
/// import 'package:timezone/standalone.dart';
///
/// initializeTimeZone().then(() {
///   final detroit = getLocation('America/Detroit');
///   final detroitNow = TZDateTime.now(detroit);
/// });
/// ```
Future<void> initializeTimeZone([String? path]) {
  path ??= tzDataDefaultPath;
  return _loadAsBytes(path).then(initializeDatabase).catchError((dynamic e) {
    throw TimeZoneInitException(e.toString());
  });
}
