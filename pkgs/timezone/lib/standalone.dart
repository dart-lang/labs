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
/// ```
library timezone.standalone;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';
import 'package:path/path.dart' as path;
import 'package:timezone/timezone.dart';

export 'package:timezone/timezone.dart'
    show getLocation, setLocalLocation, TZDateTime, Location, TimeZone, timeZoneDatabase;

final _packagesPrefix = 'packages${path.separator}';

final String tzDataDefaultPath = path.join('packages', 'timezone', 'data', tzDataDefaultFilename);

// Load file
Future<List<int>> _loadAsBytes(String p) {
  final script = Platform.script;
  final scheme = Platform.script.scheme;

  if (scheme.startsWith('http')) {
    return new HttpClient()
        .getUrl(new Uri(scheme: script.scheme, host: script.host, port: script.port, path: p))
        .then((req) {
      return req.close();
    }).then((response) {
      // join byte buffers
      return response.fold(new BytesBuilder(), (b, d) => b..add(d)).then((builder) {
        return builder.takeBytes();
      });
    });
  } else if (scheme == 'file') {
    final packageRoot = Platform.packageRoot;
    if (packageRoot.isNotEmpty && p.startsWith(_packagesPrefix)) {
      p = path.join(packageRoot, p.substring(_packagesPrefix.length));
      return new File(p).readAsBytes();
    }

    p = path.join(path.dirname(path.fromUri(script)), p);
    return new File(p).readAsBytes();
  } else if (scheme == 'data') {
    var libraryPath = currentMirrorSystem().findLibrary(#timezone.standalone).uri.path;
    var prefix = path.join(_packagesPrefix, path.dirname(libraryPath));
    p = path.join(prefix, p.substring(prefix.length + 1));
    return new File(p).readAsBytes();
  }

  return new Future.error(new UnimplementedError('Unknown script scheme: $scheme'));
}

List<int> _loadAsBytesSync(String p) {
  assert(!Platform.script.scheme.startsWith('http'));

  final script = Platform.script;
  final packageRoot = Platform.packageRoot;
  if (packageRoot.isNotEmpty && p.startsWith(_packagesPrefix)) {
    p = path.join(packageRoot, p.substring(_packagesPrefix.length));
    return new File(p).readAsBytesSync();
  }

  p = path.join(path.dirname(path.fromUri(script)), p);
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
Future initializeTimeZone([String p]) {
  if (p == null) {
    p = tzDataDefaultPath;
  }
  return _loadAsBytes(p).then((rawData) {
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
void initializeTimeZoneSync([String p]) {
  if (p == null) {
    p = tzDataDefaultPath;
  }
  try {
    final rawData = _loadAsBytesSync(p);
    initializeDatabase(rawData);
  } catch (e) {
    throw new TimeZoneInitException(e.toString());
  }
}
