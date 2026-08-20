// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Sigstore attestation and provenance verification for Dart packages.
library;

export 'src/asn1.dart' show Asn1Reader;
export 'src/models.dart';
export 'src/trusted_root.dart'
    show
        fetchLatestTrustedRootJson,
        loadTrustedRoot,
        loadTrustedRootJson,
        sigstoreTufCdn,
        tryLoadTrustedRoot,
        tryLoadTrustedRootJson,
        updateTrustedRootCache;
export 'src/verifier.dart' show AttestationVerifier;
