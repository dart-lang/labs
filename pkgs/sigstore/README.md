# Sigstore for Dart

A Dart library for parsing and verifying Sigstore attestations and SLSA provenance for Dart packages.

## Features

* **Attestation Verification:** Verifies in-toto SLSA provenance statements against package archives.
* **Certificate Root of Trust:** Validates Fulcio leaf certificates against Sigstore `trusted_root.json`.
* **Transparency Log Checking:** Validates Rekor log inclusion proofs against active log public keys.
* **Identity & Policy Enforcement:** Enforces GitHub Actions OIDC issuer, workflow path, commit SHA, and repository continuity across versions.

## Usage

```dart
import 'dart:io';
import 'package:pub_semver/pub_semver.dart';
import 'package:sigstore/sigstore.dart';

void main() {
  final verifier = AttestationVerifier();
  final bundle = SigstoreBundle.fromJson(jsonMap);

  final result = verifier.verify(
    packageName: 'helpful',
    packageVersion: Version(0, 1, 4),
    archiveBytes: File('helpful-0.1.4.tar.gz').readAsBytesSync(),
    bundle: bundle,
    pubspecRepository: 'https://github.com/mosuem/helpful',
  );

  if (result.isValid) {
    print('Verified package from ${result.repository} (${result.commitSha})');
  } else {
    print('Verification failed: ${result.errors}');
  }
}
```
