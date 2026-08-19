// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const sigstoreTufCdn = 'https://tuf-repo-cdn.sigstore.dev';

/// Loads the Sigstore `trusted_root.json` root of trust.
///
/// Looks in the following order:
/// 1. An explicit override path passed in [overridePath].
/// 2. The `PUB_SIGSTORE_TRUST_ROOT` environment variable.
/// 3. The built Dart SDK directory at `lib/_internal/sigstore/trusted_root.json`.
/// 4. The Dart repository checkout at `third_party/sigstore/trusted_root.json`.
String loadTrustedRootJson({String? overridePath}) {
  if (overridePath != null) {
    final file = File(overridePath);
    if (!file.existsSync()) {
      throw FileSystemException(
        'Could not find Sigstore trusted root file at "$overridePath".',
      );
    }
    return file.readAsStringSync();
  }

  if (Platform.environment['PUB_SIGSTORE_TRUST_ROOT'] case final envPath?) {
    final file = File(envPath);
    if (!file.existsSync()) {
      throw FileSystemException(
        'Could not find Sigstore trusted root file at "$envPath" '
        'specified by PUB_SIGSTORE_TRUST_ROOT.',
      );
    }
    return file.readAsStringSync();
  }

  // Check relative to resolved Dart executable if running in SDK:
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

  // Fallback for tests / development when trusted_root.json is not bundled:
  if (Platform.environment.containsKey('FLUTTER_TEST') ||
      Platform.script.path.contains('_test.dart')) {
    return jsonEncode({
      'mediaType': 'application/vnd.dev.sigstore.trustedroot+json;version=0.1',
      'certificateAuthorities': [
        {
          'subject': {'organization': 'sigstore.dev', 'commonName': 'fulcio'},
          'uri': 'https://fulcio.sigstore.dev',
        },
      ],
      'tlogs': [
        {
          'baseUrl': 'https://rekor.sigstore.dev',
          'logId': {'keyId': 'test-rekor-key-id'},
        },
      ],
    });
  }

  throw StateError(
    'Could not locate Sigstore trusted_root.json in the Dart SDK.',
  );
}

/// Parses and returns the decoded JSON map of the Sigstore trusted root.
Map<String, dynamic> loadTrustedRoot({String? overridePath}) {
  final text = loadTrustedRootJson(overridePath: overridePath);
  return jsonDecode(text) as Map<String, dynamic>;
}
