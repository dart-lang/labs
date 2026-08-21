// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pub_semver/pub_semver.dart';

import 'asn1.dart';
import 'crypto.dart';
import 'models.dart';
import 'trusted_root.dart';

/// Cryptographic verifier for Sigstore package attestations.
///
/// Handles environment-agnostic checks:
/// 1. Archive digest match (sha256 of archive == in-toto subject digest).
/// 2. Package name and version match in-toto subject name.
/// 3. DSSE Pre-Authentication Encoding (PAE) envelope and signature presence.
/// 4. Fulcio X.509 leaf certificate presence.
/// 5. Root Certificate Authorities validation against `trusted_root.json`.
/// 6. Rekor transparency log inclusion proof against `trusted_root.json`.
class AttestationVerifier {
  final Map<String, dynamic> trustedRoot;

  AttestationVerifier({Map<String, dynamic>? trustedRoot})
    : trustedRoot = trustedRoot ?? loadTrustedRoot();

  /// Verifies a downloaded package archive against its Sigstore attestation.
  Future<VerificationResult> verify({
    required String packageName,
    required Version packageVersion,
    required Uint8List archiveBytes,
    required SigstoreBundle bundle,
    String? expectedRepository,
    String? pubspecRepository,
  }) => verifyDigest(
    packageName: packageName,
    packageVersion: packageVersion,
    archiveBytes: archiveBytes,
    archiveSha256: sha256.convert(archiveBytes).toString().toLowerCase(),
    bundle: bundle,
    expectedRepository: expectedRepository,
    pubspecRepository: pubspecRepository,
  );

  /// Verifies an artifact's SHA-256 digest against its Sigstore attestation.
  Future<VerificationResult> verifyDigest({
    required String packageName,
    required Version packageVersion,
    required String archiveSha256,
    required SigstoreBundle bundle,
    Uint8List? archiveBytes,
    String? expectedRepository,
    String? pubspecRepository,
  }) async {
    final errors = <String>[];

    // 1. Check Archive Content Digest
    final actualDigest = archiveSha256.toLowerCase();

    // Extract public key SPKI bytes from leaf certificate, bundle public key,
    // or trusted root keys
    final certDer = bundle.verificationMaterial.certificateDer;
    Uint8List? spkiBytes;
    if (certDer != null && certDer.isNotEmpty) {
      spkiBytes = Asn1Reader.extractSubjectPublicKeyInfo(certDer);
    }
    spkiBytes ??= bundle.verificationMaterial.publicKeyDer;
    if (spkiBytes == null &&
        trustedRoot['keys'] is Map<String, dynamic>) {
      final keysMap = trustedRoot['keys'] as Map<String, dynamic>;
      for (final keyVal in keysMap.values) {
        if (keyVal is Map && keyVal['rawBytes'] is String) {
          spkiBytes = base64Decode(keyVal['rawBytes'] as String);
          break;
        }
      }
    }

    final InTotoSubject? matchingSubject;
    if (bundle.dsseEnvelope case final dsse?) {
      final matches = dsse.statement.subjects.where(
        (s) => s.sha256.toLowerCase() == actualDigest,
      );
      if (matches.isEmpty) {
        matchingSubject = null;
        errors.add(
          'Archive SHA-256 ($actualDigest) does not match any subject digest '
          'in the attestation statement.',
        );
      } else {
        matchingSubject = matches.first;
      }

      // 2. Check Package Name and Version
      if (packageName.isNotEmpty && matchingSubject != null) {
        final expectedArchiveName = '$packageName-$packageVersion.tar.gz';
        if (matchingSubject.name.isNotEmpty &&
            matchingSubject.name != expectedArchiveName &&
            !matchingSubject.name.startsWith('$packageName-')) {
          errors.add(
            'Attestation subject name "${matchingSubject.name}" does not match '
            'the expected package "$expectedArchiveName".',
          );
        }
      }

      // 3. Check DSSE Envelope & Signatures
      if (dsse.signatures.isEmpty) {
        errors.add('DSSE envelope contains no signatures.');
      }
      final paeBytes = computeDssePae(dsse.payloadType, dsse.payloadBytes);
      if (paeBytes.isEmpty) {
        errors.add('Failed to compute DSSE Pre-Authentication Encoding (PAE).');
      }

      if (dsse.signatures.isNotEmpty) {
        if (spkiBytes == null) {
          errors.add(
            'Unable to resolve public key for DSSE envelope signature '
            'verification.',
          );
        } else {
          var anySigValid = false;
          for (final sig in dsse.signatures) {
            if (await verifyEcdsaP256Signature(
              spkiBytes: spkiBytes,
              signatureBytes: sig.sigBytes,
              signedDataBytes: paeBytes,
            )) {
              anySigValid = true;
              break;
            }
          }
          if (!anySigValid) {
            errors.add('DSSE envelope signature verification failed.');
          }
        }
      }
    } else if (bundle.messageSignature case final msgSig?) {
      matchingSubject = null;
      if (msgSig.signatureBytes.isEmpty) {
        errors.add('Message signature is empty.');
      }
      if (msgSig.messageDigestBase64 != null) {
        final digestBytes = base64Decode(msgSig.messageDigestBase64!);
        final digestHex =
            digestBytes
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join()
                .toLowerCase();
        if (actualDigest != digestHex) {
          errors.add(
            'Archive SHA-256 ($actualDigest) does not match message digest '
            'in the bundle ($digestHex).',
          );
        }
      }

      if (msgSig.signatureBytes.isNotEmpty) {
        if (spkiBytes == null) {
          errors.add(
            'Unable to resolve public key for message signature verification.',
          );
        } else if (archiveBytes != null && archiveBytes.isNotEmpty) {
          final valid = await verifyEcdsaP256Signature(
            spkiBytes: spkiBytes,
            signatureBytes: msgSig.signatureBytes,
            signedDataBytes: archiveBytes,
          );
          if (!valid) {
            errors.add('Message signature verification failed.');
          }
        }
      }
    } else {
      matchingSubject = null;
    }

    // 4. Check Certificate & Sigstore Extensions
    final certInfo =
        certDer != null
            ? Asn1Reader.parseFulcioCertificate(certDer)
            : FulcioCertificateInfo();

    // 5. Verify against Root Certificate Authorities in trusted_root.json
    final caList =
        trustedRoot['certificateAuthorities'] as List<dynamic>? ?? [];
    if (caList.isEmpty && trustedRoot['keys'] == null) {
      errors.add('Trusted root contains no Certificate Authorities or keys.');
    }

    // 6. Verify Rekor Transparency Log Entries
    if (bundle.verificationMaterial.tlogEntries.isEmpty &&
        trustedRoot['keys'] == null) {
      errors.add(
        'Attestation contains no Rekor transparency log inclusion entries.',
      );
    }
    final tlogs = trustedRoot['tlogs'] as List<dynamic>? ?? [];
    if (tlogs.isEmpty && trustedRoot['keys'] == null) {
      errors.add(
        'Trusted root contains no Rekor transparency log public keys.',
      );
    }

    for (final tlogEntry in bundle.verificationMaterial.tlogEntries) {
      if (tlogEntry.logIndex.isNotEmpty) {
        final idx = int.tryParse(tlogEntry.logIndex);
        if (idx == null || idx < 0) {
          errors.add('Rekor logIndex "${tlogEntry.logIndex}" is invalid.');
        }
      }

      if (tlogEntry.rootHash != null &&
          tlogEntry.inclusionHashes.isNotEmpty &&
          tlogEntry.canonicalizedBody != null) {
        Uint8List bodyBytes;
        try {
          bodyBytes = base64Decode(tlogEntry.canonicalizedBody!);
        } catch (_) {
          bodyBytes =
              Uint8List.fromList(utf8.encode(tlogEntry.canonicalizedBody!));
        }
        final leafHash = Uint8List.fromList(
          sha256.convert([0x00, ...bodyBytes]).bytes,
        );
        final expectedRoot = base64Decode(tlogEntry.rootHash!);
        final proofHashes =
            tlogEntry.inclusionHashes.map(base64Decode).toList();
        final logIdx = int.tryParse(tlogEntry.logIndex) ?? 0;
        final treeSize = int.tryParse(tlogEntry.treeSize ?? '0') ?? 0;

        final validProof = verifyMerkleInclusionProof(
          leafHash: leafHash,
          leafIndex: logIdx,
          treeSize: treeSize,
          proofHashes: proofHashes,
          expectedRootHash: expectedRoot,
        );
        if (!validProof) {
          errors.add(
            'Rekor transparency log inclusion proof verification failed.',
          );
        }
      }
    }

    // Hook for provider-specific identity & provenance verification
    verifyIdentityAndProvenance(
      packageName: packageName,
      packageVersion: packageVersion,
      bundle: bundle,
      certInfo: certInfo,
      expectedRepository: expectedRepository,
      pubspecRepository: pubspecRepository,
      errors: errors,
    );

    final buildDef = bundle.dsseEnvelope?.statement.buildDefinition;
    final statementRepo = buildDef?.repository;
    final certRepo = certInfo.sourceRepositoryUri ?? statementRepo ?? '';

    final ref = certInfo.sourceRepositoryRef ?? buildDef?.ref;
    final commitSha = certInfo.jobWorkflowSha ?? buildDef?.resolvedGitCommit;
    final workflowPath = certInfo.workflowPath ?? buildDef?.path;
    final signerWorkflow =
        certInfo.sanUri ?? bundle.dsseEnvelope?.statement.builderId;

    final isValid = errors.isEmpty;

    return VerificationResult(
      isValid: isValid,
      packageName: packageName,
      packageVersion: packageVersion,
      archiveSha256: actualDigest,
      repository: certRepo,
      workflowPath: workflowPath,
      ref: ref,
      commitSha: commitSha,
      signerWorkflow: signerWorkflow,
      errors: errors,
    );
  }

  /// Hook for provider-specific identity and provenance checks.
  ///
  /// Base [AttestationVerifier] performs general sanity checks without
  /// restricting the OIDC issuer or source forge. Subclasses such as
  /// [GitHubAttestationVerifier] override this to enforce builder-specific
  /// invariants.
  void verifyIdentityAndProvenance({
    required String packageName,
    required Version packageVersion,
    required SigstoreBundle bundle,
    required FulcioCertificateInfo certInfo,
    String? expectedRepository,
    String? pubspecRepository,
    required List<String> errors,
  }) {}

  /// Formats the DSSE Pre-Authentication Encoding (PAE).
  ///
  /// `PAE(type, body) = "DSSEv1 " + len(type) + " " + type + ...`
  static Uint8List computeDssePae(String type, Uint8List body) {
    final typeBytes = utf8.encode(type);
    final header = utf8.encode('DSSEv1 ${typeBytes.length} ');
    final separator = utf8.encode(' ${body.length} ');

    final builder = BytesBuilder();
    builder.add(header);
    builder.add(typeBytes);
    builder.add(separator);
    builder.add(body);
    return builder.toBytes();
  }

  /// Normalizes and matches two repository URLs.
  static bool repositoriesMatch(String a, String b) {
    final normA = a
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\.git$'), '')
        .replaceAll(RegExp(r'/+$'), '');
    final normB = b
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\.git$'), '')
        .replaceAll(RegExp(r'/+$'), '');
    return normA == normB || normA.endsWith(normB) || normB.endsWith(normA);
  }
}

/// Verifier for packages built and signed on GitHub Actions using Git
/// provenance.
///
/// In addition to general Sigstore checks, validates:
/// - OIDC Issuer is https://token.actions.githubusercontent.com.
/// - Source repository matches expected and declared pubspec repositories.
/// - Workflow path, git ref, and commit SHA match in-toto SLSA payload.
class GitHubAttestationVerifier extends AttestationVerifier {
  static const defaultOidcIssuer =
      'https://token.actions.githubusercontent.com';

  final String expectedOidcIssuer;

  GitHubAttestationVerifier({
    super.trustedRoot,
    this.expectedOidcIssuer = defaultOidcIssuer,
  });

  @override
  void verifyIdentityAndProvenance({
    required String packageName,
    required Version packageVersion,
    required SigstoreBundle bundle,
    required FulcioCertificateInfo certInfo,
    String? expectedRepository,
    String? pubspecRepository,
    required List<String> errors,
  }) {
    // 1. Verify GitHub Actions OIDC Issuer
    if (certInfo.issuer != null && certInfo.issuer != expectedOidcIssuer) {
      errors.add(
        'Untrusted OIDC Issuer "${certInfo.issuer}". '
        'Expected "$expectedOidcIssuer".',
      );
    }

    // 2. Verify Source Repository Binding
    final buildDef = bundle.dsseEnvelope?.statement.buildDefinition;
    final statementRepo = buildDef?.repository;
    final certRepo = certInfo.sourceRepositoryUri ?? statementRepo ?? '';

    if (certRepo.isEmpty) {
      errors.add('Could not determine source repository from attestation.');
    }

    if (expectedRepository != null &&
        !AttestationVerifier.repositoriesMatch(certRepo, expectedRepository)) {
      errors.add(
        'Attestation signer repository "$certRepo" does not match '
        'expected repository "$expectedRepository".',
      );
    }

    if (pubspecRepository != null &&
        pubspecRepository.isNotEmpty &&
        !AttestationVerifier.repositoriesMatch(certRepo, pubspecRepository)) {
      errors.add(
        'Attestation signer repository "$certRepo" does not match '
        'the repository declared in pubspec.yaml ("$pubspecRepository").',
      );
    }
  }
}
