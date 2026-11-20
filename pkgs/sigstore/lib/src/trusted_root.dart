// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const sigstoreTufCdn =
    'https://raw.githubusercontent.com/sigstore/root-signing/main/targets/trusted_root.json';

/// Attempts to load the Sigstore `trusted_root.json` root of trust.
/// Returns `null` if the file could not be found.
String? tryLoadTrustedRootJson({String? cachePath, String? overridePath}) {
  if (overridePath != null) {
    final file = File(overridePath);
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  for (final envKey in [
    'PUB_SIGSTORE_TRUST_ROOT',
    'SIGSTORE_TRUST_ROOT',
    'SIGSTORE_TRUSTED_ROOT',
  ]) {
    if (Platform.environment[envKey] case final envPath?) {
      final file = File(envPath);
      return file.existsSync() ? file.readAsStringSync() : null;
    }
  }

  // 1. Check user cache (updated / cached root of trust):
  if (cachePath != null && File(cachePath).existsSync()) {
    return File(cachePath).readAsStringSync();
  }
  if (Platform.environment['PUB_CACHE'] case final pubCache?) {
    final cachedRoot = p.join(pubCache, 'sigstore', 'trusted_root.json');
    if (File(cachedRoot).existsSync()) {
      return File(cachedRoot).readAsStringSync();
    }
  }

  // 2. Check relative to resolved Dart executable if running in SDK:
  final exeDir = p.dirname(Platform.resolvedExecutable);
  final sdkRoot = p.dirname(exeDir);
  final sdkPath = p.join(
    sdkRoot,
    'lib',
    '_internal',
    'sigstore',
    'trusted_root.json',
  );
  if (File(sdkPath).existsSync()) {
    return File(sdkPath).readAsStringSync();
  }

  final repoPath = p.join(
    p.dirname(sdkRoot),
    'third_party',
    'sigstore',
    'trusted_root.json',
  );
  if (File(repoPath).existsSync()) {
    return File(repoPath).readAsStringSync();
  }

  return null;
}

/// Attempts to parse and return the decoded JSON map of the Sigstore trusted
/// root.
/// Returns `null` if not found.
Map<String, dynamic>? tryLoadTrustedRoot({
  String? cachePath,
  String? overridePath,
}) {
  final text = tryLoadTrustedRootJson(
    cachePath: cachePath,
    overridePath: overridePath,
  );
  if (text == null) return null;
  return jsonDecode(text) as Map<String, dynamic>;
}

/// Loads the Sigstore `trusted_root.json` root of trust.
/// Throws [StateError] or [FileSystemException] if not found.
String loadTrustedRootJson({String? cachePath, String? overridePath}) {
  if (overridePath != null) {
    final file = File(overridePath);
    if (!file.existsSync()) {
      throw FileSystemException(
        'Could not find Sigstore trusted root file at "$overridePath".',
      );
    }
    return file.readAsStringSync();
  }

  for (final envKey in [
    'PUB_SIGSTORE_TRUST_ROOT',
    'SIGSTORE_TRUST_ROOT',
    'SIGSTORE_TRUSTED_ROOT',
  ]) {
    if (Platform.environment[envKey] case final envPath?) {
      final file = File(envPath);
      if (!file.existsSync()) {
        throw FileSystemException(
          'Could not find Sigstore trusted root file at "$envPath" '
          'specified by $envKey.',
        );
      }
      return file.readAsStringSync();
    }
  }

  final json = tryLoadTrustedRootJson(cachePath: cachePath);
  if (json != null) return json;

  throw StateError(
    'Could not locate Sigstore trusted_root.json in the Dart SDK.',
  );
}

/// Parses and returns the decoded JSON map of the Sigstore trusted root.
Map<String, dynamic> loadTrustedRoot({
  String? cachePath,
  String? overridePath,
}) {
  final text = loadTrustedRootJson(
    cachePath: cachePath,
    overridePath: overridePath,
  );
  return jsonDecode(text) as Map<String, dynamic>;
}

/// Fetches the latest trusted root JSON from Sigstore's TUF CDN repository.
Future<String> fetchLatestTrustedRootJson({
  String cdnUrl = sigstoreTufCdn,
  HttpClient? customHttpClient,
}) async {
  final uri = Uri.parse(cdnUrl);
  final client = customHttpClient ?? HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return await utf8.decoder.bind(response).join();
    }
    throw HttpException(
      'Failed to fetch Sigstore trusted root from $uri '
      '(status: ${response.statusCode})',
      uri: uri,
    );
  } finally {
    if (customHttpClient == null) {
      client.close();
    }
  }
}

/// Updates the cached trusted_root.json at [cachePath] with the latest from
/// [cdnUrl].
Future<void> updateTrustedRootCache({
  required String cachePath,
  String cdnUrl = sigstoreTufCdn,
  HttpClient? customHttpClient,
}) async {
  final content = await fetchLatestTrustedRootJson(
    cdnUrl: cdnUrl,
    customHttpClient: customHttpClient,
  );
  jsonDecode(content);
  final file = File(cachePath);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}
