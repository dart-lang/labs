// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  final mockTrustedRoot = {
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
  };

  Map<String, dynamic> createTestBundleJson({
    required String archiveSha256,
    String packageName = 'helpful',
    String packageVersion = '0.1.4',
    String repository = 'https://github.com/mosuem/helpful',
    String issuer = 'https://token.actions.githubusercontent.com',
  }) {
    final statement = {
      '_type': 'https://in-toto.io/Statement/v1',
      'subject': [
        {
          'name': '$packageName-$packageVersion.tar.gz',
          'digest': {'sha256': archiveSha256},
        },
      ],
      'predicateType': 'https://slsa.dev/provenance/v1',
      'predicate': {
        'buildDefinition': {
          'buildType': 'https://actions.github.io/buildtypes/workflow/v1',
          'externalParameters': {
            'workflow': {
              'ref': 'refs/tags/v$packageVersion',
              'repository': repository,
              'path': '.github/workflows/publish.yaml',
            },
          },
          'resolvedDependencies': [
            {
              'uri': 'git+$repository@refs/tags/v$packageVersion',
              'digest': {
                'gitCommit': '7891abbe3dab159e9d0187fc1042d5e0cd82cfad',
              },
            },
          ],
        },
      },
    };

    final payloadBase64 = base64Encode(utf8.encode(jsonEncode(statement)));
    final issuerBytes = utf8.encode(issuer);
    final repoBytes = utf8.encode(repository);
    final derBytes = <int>[
      0x30,
      0x82,
      0x01,
      0x00,
      0x2B,
      0x06,
      0x01,
      0x04,
      0x01,
      0x83,
      0xBF,
      0x30,
      0x01,
      0x01,
      0x0C,
      issuerBytes.length,
      ...issuerBytes,
      0x2B,
      0x06,
      0x01,
      0x04,
      0x01,
      0x83,
      0xBF,
      0x30,
      0x01,
      0x05,
      0x0C,
      repoBytes.length,
      ...repoBytes,
    ];

    return {
      'mediaType': 'application/vnd.dev.sigstore.bundle.v0.3+json',
      'verificationMaterial': {
        'certificate': {'rawBytes': base64Encode(derBytes)},
        'tlogEntries': [
          {
            'logIndex': '123456',
            'inclusionProof': {
              'rootHash': 'test-root-hash',
              'hashes': ['hash1', 'hash2'],
            },
          },
        ],
      },
      'dsseEnvelope': {
        'payloadType': 'application/vnd.in-toto+json',
        'payload': payloadBase64,
        'signatures': [
          {'sig': base64Encode(utf8.encode('test-signature'))},
        ],
      },
    };
  }

  test(
    'conformance CLI verify-bundle succeeds with valid bundle and identity',
    () async {
      final archiveBytes = Uint8List.fromList(
        utf8.encode('fake-artifact-content'),
      );
      final archiveSha = sha256.convert(archiveBytes).toString();

      final bundleJson = createTestBundleJson(archiveSha256: archiveSha);

      await d.file('bundle.sigstore.json', jsonEncode(bundleJson)).create();
      await d.file('artifact.tar.gz', archiveBytes).create();
      await d.file('trusted_root.json', jsonEncode(mockTrustedRoot)).create();

      final bundlePath = p.join(d.sandbox, 'bundle.sigstore.json');
      final artifactPath = p.join(d.sandbox, 'artifact.tar.gz');
      final trustedRootPath = p.join(d.sandbox, 'trusted_root.json');

      final result = await Process.run(
        Platform.executable,
        [
          'run',
          'bin/conformance.dart',
          'verify-bundle',
          '--bundle',
          bundlePath,
          '--certificate-identity',
          'https://github.com/mosuem/helpful',
          '--certificate-oidc-issuer',
          'https://token.actions.githubusercontent.com',
          artifactPath,
        ],
        environment: {'SIGSTORE_TRUSTED_ROOT': trustedRootPath},
      );

      expect(
        result.exitCode,
        equals(0),
        reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
      );
    },
  );

  test('conformance CLI verify-bundle fails on OIDC issuer mismatch', () async {
    final archiveBytes = Uint8List.fromList(
      utf8.encode('fake-artifact-content'),
    );
    final archiveSha = sha256.convert(archiveBytes).toString();

    final bundleJson = createTestBundleJson(
      archiveSha256: archiveSha,
      issuer: 'https://accounts.google.com',
    );

    await d.file('bundle.sigstore.json', jsonEncode(bundleJson)).create();
    await d.file('artifact.tar.gz', archiveBytes).create();
    await d.file('trusted_root.json', jsonEncode(mockTrustedRoot)).create();

    final bundlePath = p.join(d.sandbox, 'bundle.sigstore.json');
    final artifactPath = p.join(d.sandbox, 'artifact.tar.gz');
    final trustedRootPath = p.join(d.sandbox, 'trusted_root.json');

    final result = await Process.run(
      Platform.executable,
      [
        'run',
        'bin/conformance.dart',
        'verify-bundle',
        '--bundle',
        bundlePath,
        '--certificate-identity',
        'https://github.com/mosuem/helpful',
        '--certificate-oidc-issuer',
        'https://token.actions.githubusercontent.com',
        artifactPath,
      ],
      environment: {'SIGSTORE_TRUSTED_ROOT': trustedRootPath},
    );

    expect(result.exitCode, equals(1));
    expect(result.stderr, contains('OIDC Issuer mismatch'));
  });

  test(
    'conformance CLI verify-bundle fails on artifact digest mismatch',
    () async {
      final archiveBytes = Uint8List.fromList(
        utf8.encode('tampered-artifact-content'),
      );

      final bundleJson = createTestBundleJson(
        archiveSha256:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );

      await d.file('bundle.sigstore.json', jsonEncode(bundleJson)).create();
      await d.file('artifact.tar.gz', archiveBytes).create();
      await d.file('trusted_root.json', jsonEncode(mockTrustedRoot)).create();

      final bundlePath = p.join(d.sandbox, 'bundle.sigstore.json');
      final artifactPath = p.join(d.sandbox, 'artifact.tar.gz');
      final trustedRootPath = p.join(d.sandbox, 'trusted_root.json');

      final result = await Process.run(
        Platform.executable,
        [
          'run',
          'bin/conformance.dart',
          'verify-bundle',
          '--bundle',
          bundlePath,
          '--certificate-identity',
          'https://github.com/mosuem/helpful',
          '--certificate-oidc-issuer',
          'https://token.actions.githubusercontent.com',
          artifactPath,
        ],
        environment: {'SIGSTORE_TRUSTED_ROOT': trustedRootPath},
      );

      expect(result.exitCode, equals(1));
    },
  );

  test('conformance CLI sign-bundle exits with error', () async {
    final result = await Process.run(Platform.executable, [
      'run',
      'bin/conformance.dart',
      'sign-bundle',
    ]);

    expect(result.exitCode, equals(1));
    expect(result.stderr, contains('sign-bundle is not implemented'));
  });
}
