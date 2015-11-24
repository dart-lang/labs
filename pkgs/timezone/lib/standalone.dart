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
///  final now = new TZDateTime.now(detroit);
/// });
library timezone.standalone;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:path/path.dart' as ospath;
import 'package:timezone/timezone.dart';

export 'package:timezone/timezone.dart' show getLocation, setLocalLocation,
    TZDateTime, Location, TimeZone, timeZoneDatabase;

final _packagesPrefix = 'packages${ospath.separator}';

final String tzDataDefaultPath = ospath.join('packages',
    'timezone', 'data', tzDataDefaultFilename);

/// Load file
Future<List<int>> _loadAsBytes(String path) {
  final script = Platform.script;
  final scheme = Platform.script.scheme;

  if (scheme.startsWith('http')) {
    return new HttpClient().getUrl(
        new Uri(
            scheme: script.scheme,
            host: script.host,
            port: script.port,
            path: path)).then((req) {
      return req.close();
    }).then((response) {
      // join byte buffers
      return response.fold(
          new BytesBuilder(),
          (b, d) => b..add(d)).then((builder) {
        return builder.takeBytes();
      });
    });

  } else if (scheme == 'file') {
    final packageRoot = Platform.packageRoot;
    if (packageRoot.isNotEmpty && path.startsWith(_packagesPrefix)) {
      final p = ospath.join(packageRoot, path.substring(_packagesPrefix.length));
      return new File(p).readAsBytes();
    }

    final p = ospath.join(ospath.dirname(ospath.fromUri(script)), path);
    return new File(p).readAsBytes();
  } else if (scheme == 'data') {
    var libraryPath = currentMirrorSystem().findLibrary(#timezone.standalone).uri.path;
    var prefix = ospath.join(_packagesPrefix, ospath.dirname(libraryPath));
    var p = ospath.join(prefix, path.substring(prefix.length + 1));
    return new File(p).readAsBytes();
  }

  return new Future.error(new UnimplementedError('Unknown script scheme: $scheme'));
}

List<int> _loadAsBytesSync(String path) {
  assert(!Platform.script.scheme.startsWith('http'));

  final script = Platform.script;
  final packageRoot = Platform.packageRoot;
  if (packageRoot.isNotEmpty && path.startsWith(_packagesPrefix)) {
    final p = ospath.join(packageRoot, path.substring(_packagesPrefix.length));
    return new File(p).readAsBytesSync();
  }

  final p = ospath.join(ospath.dirname(ospath.fromUri(script)), path);
  return new File(p).readAsBytesSync();
}

/// Initialize Time Zone database.
///
/// Throws [TimeZoneInitException] when something is worng.
///
/// ```dart
/// import 'package:timezone/standalone.dart';
///
/// initializeTimeZone().then(() {
///   final detroit = getLocation('America/Detroit');
///   final detroitNow = new TZDateTime.now(detroit);
/// });
/// ```
Future initializeTimeZone([String path]) {
  if (path == null) {
    path = tzDataDefaultPath;
  }
  return _loadAsBytes(path).then((rawData) {
    initializeDatabase(rawData);
  }).catchError((e) {
    throw new TimeZoneInitException(e.toString());
  });
}

/// Initialize Time Zone database (Sync).
///
/// Throws [TimeZoneInitException] when something is worng.
///
/// ```dart
/// import 'package:timezone/standalone.dart';
///
/// initializeTimeZoneSync();
/// final detroit = getLocation('America/Detroit');
/// final detroitNow = new TZDateTime.now(detroit);
/// ```
void initializeTimeZoneSync([String path]) {
  if (path == null) {
    path = tzDataDefaultPath;
  }
  try {
    final rawData = _loadAsBytesSync(path);
    initializeDatabase(rawData);
  } catch (e) {
    throw new TimeZoneInitException(e.toString());
  }
}
