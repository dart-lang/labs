// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:webcrypto/webcrypto.dart';

import 'asn1.dart';

/// Converts ASN.1 DER ECDSA signature `SEQUENCE { INTEGER r, INTEGER s }`
/// to IEEE P1363 raw `r || s` (64 bytes for P-256).
Uint8List derToP1363(Uint8List sigBytes, {int keySize = 32}) {
  if (sigBytes.length == keySize * 2) {
    return sigBytes;
  }
  if (sigBytes.isEmpty || sigBytes[0] != 0x30) {
    return sigBytes;
  }
  try {
    final reader = Asn1Reader(sigBytes);
    reader.readTag(); // 0x30
    reader.readLength();

    if (reader.readTag() != 0x02) return sigBytes;
    final rLen = reader.readLength();
    var r = reader.readBytes(rLen);
    while (r.length > keySize && r[0] == 0) {
      r = r.sublist(1);
    }

    if (reader.readTag() != 0x02) return sigBytes;
    final sLen = reader.readLength();
    var s = reader.readBytes(sLen);
    while (s.length > keySize && s[0] == 0) {
      s = s.sublist(1);
    }

    final out = Uint8List(keySize * 2);
    out.setRange(keySize - r.length, keySize, r);
    out.setRange(keySize * 2 - s.length, keySize * 2, s);
    return out;
  } catch (_) {
    return sigBytes;
  }
}

/// Verifies an ECDSA NIST P-256 signature against data using [EcdsaPublicKey].
Future<bool> verifyEcdsaP256Signature({
  required Uint8List spkiBytes,
  required Uint8List signatureBytes,
  required Uint8List signedDataBytes,
}) async {
  try {
    final publicKey = await EcdsaPublicKey.importSpkiKey(
      spkiBytes,
      EllipticCurve.p256,
    );
    final p1363Signature = derToP1363(signatureBytes, keySize: 32);
    return await publicKey.verifyBytes(
      p1363Signature,
      signedDataBytes,
      Hash.sha256,
    );
  } catch (_) {
    return false;
  }
}

/// Verifies an RFC 6962 Merkle tree inclusion proof.
bool verifyMerkleInclusionProof({
  required Uint8List leafHash,
  required int leafIndex,
  required int treeSize,
  required List<Uint8List> proofHashes,
  required Uint8List expectedRootHash,
}) {
  if (leafIndex < 0 || (treeSize > 0 && leafIndex >= treeSize)) {
    return false;
  }
  var fn = leafIndex;
  var sn = treeSize > 0 ? treeSize - 1 : leafIndex;
  var r = leafHash;

  for (final p in proofHashes) {
    if (sn == 0) return false;
    if (fn.isOdd || fn == sn) {
      r = Uint8List.fromList(
        crypto.sha256.convert([0x01, ...p, ...r]).bytes,
      );
      while (fn.isEven && fn != 0) {
        fn ~/= 2;
        sn ~/= 2;
      }
    } else {
      r = Uint8List.fromList(
        crypto.sha256.convert([0x01, ...r, ...p]).bytes,
      );
    }
    fn ~/= 2;
    sn ~/= 2;
  }

  if (r.length != expectedRootHash.length) return false;
  for (var i = 0; i < r.length; i++) {
    if (r[i] != expectedRootHash[i]) return false;
  }
  return true;
}
