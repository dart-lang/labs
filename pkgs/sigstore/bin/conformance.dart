// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sigstore/sigstore.dart';

/// Entrypoint implementing the `sigstore-conformance` CLI protocol.
///
/// See https://github.com/sigstore/sigstore-conformance/blob/main/docs/cli_protocol.md
void main(List<String> args) async {
  final parser =
      ArgParser()
        ..addCommand('verify-bundle')
        ..addCommand('sign-bundle');

  parser.commands['verify-bundle']!
    ..addOption('bundle', help: 'Path to Sigstore bundle file', mandatory: true)
    ..addOption(
      'certificate-identity',
      help: 'Expected certificate identity (SAN URI / Subject)',
      mandatory: true,
    )
    ..addOption(
      'certificate-oidc-issuer',
      help: 'Expected OIDC issuer URL',
      mandatory: true,
    )
    ..addFlag(
      'staging',
      help: 'Use Sigstore staging infrastructure',
      defaultsTo: false,
    );

  final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('Argument parsing error: ${e.message}');
    exit(1);
  }

  final command = results.command;
  if (command == null) {
    stderr.writeln('No subcommand specified. Expected "verify-bundle".');
    exit(1);
  }

  if (command.name == 'sign-bundle') {
    stderr.writeln('sign-bundle is not implemented for this client.');
    exit(1);
  }

  if (command.name != 'verify-bundle') {
    stderr.writeln('Unknown command: ${command.name}');
    exit(1);
  }

  final bundlePath = command['bundle'] as String;
  final expectedIdentity = command['certificate-identity'] as String;
  final expectedIssuer = command['certificate-oidc-issuer'] as String;
  final isStaging = command['staging'] as bool;
  final positionalArgs = command.rest;

  try {
    final bundleFile = File(bundlePath);
    if (!await bundleFile.exists()) {
      stderr.writeln('Bundle file does not exist: $bundlePath');
      exit(1);
    }

    final bundleJson =
        jsonDecode(await bundleFile.readAsString()) as Map<String, dynamic>;
    final bundle = SigstoreBundle.fromJson(bundleJson);

    var artifactBytes = Uint8List(0);
    String? expectedSha256;

    if (positionalArgs.isNotEmpty) {
      final input = positionalArgs.first;
      if (input.startsWith('sha256:') && input.length == 71) {
        expectedSha256 = input.substring(7).toLowerCase();
      } else {
        final artifactFile = File(input);
        if (await artifactFile.exists()) {
          artifactBytes = await artifactFile.readAsBytes();
          expectedSha256 =
              sha256.convert(artifactBytes).toString().toLowerCase();
        } else {
          stderr.writeln('Artifact file does not exist: $input');
          exit(1);
        }
      }
    }

    // Load appropriate trusted root
    final Map<String, dynamic> trustedRoot;
    if (isStaging) {
      final stagingJson = await fetchLatestTrustedRootJson(
        cdnUrl: 'https://tuf-staging.sigstore.dev',
      );
      trustedRoot = jsonDecode(stagingJson) as Map<String, dynamic>;
    } else {
      trustedRoot = loadTrustedRoot();
    }

    // Verify bundle envelope and signatures
    final verifier = AttestationVerifier(trustedRoot: trustedRoot);
    final result = verifier.verify(
      packageName: '',
      packageVersion: Version.none,
      archiveBytes: artifactBytes,
      bundle: bundle,
    );

    // If expectedSha256 is provided, ensure subject or artifact matched
    if (expectedSha256 != null &&
        result.archiveSha256.isNotEmpty &&
        result.archiveSha256.toLowerCase() != expectedSha256) {
      stderr.writeln(
        'Digest mismatch: expected $expectedSha256 but got '
        '${result.archiveSha256}',
      );
      exit(1);
    }

    // Verify certificate identity and OIDC issuer
    final certDer = bundle.verificationMaterial.certificateDer;
    if (certDer == null || certDer.isEmpty) {
      stderr.writeln('No certificate found in verification material.');
      exit(1);
    }

    final certInfo = Asn1Reader.parseFulcioCertificate(certDer);

    if (certInfo.issuer != null && certInfo.issuer != expectedIssuer) {
      stderr.writeln(
        'OIDC Issuer mismatch: expected "$expectedIssuer" but got '
        '"${certInfo.issuer}"',
      );
      exit(1);
    }

    final certIdentities = [
      if (certInfo.sanUri != null) certInfo.sanUri!,
      if (certInfo.sourceRepositoryUri != null) certInfo.sourceRepositoryUri!,
    ];

    if (certIdentities.isNotEmpty &&
        !certIdentities.any(
          (id) =>
              id == expectedIdentity ||
              id.endsWith(expectedIdentity) ||
              expectedIdentity.endsWith(id),
        )) {
      stderr.writeln(
        'Certificate identity mismatch: expected "$expectedIdentity" '
        'but got ${certIdentities.join(', ')}',
      );
      exit(1);
    }

    if (!result.isValid) {
      stderr.writeln('Verification failed: ${result.errors.join('; ')}');
      exit(1);
    }

    exit(0);
  } catch (e, st) {
    stderr.writeln('Error verifying bundle: $e\n$st');
    exit(1);
  }
}
