// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';
import 'package:sigstore/sigstore.dart';
import 'package:test/test.dart';

void main() {
  test('allows signed package when previously locked version was signed', () {
    final prev = ProvenanceInfo(
      repository: 'https://github.com/mosuem/helpful',
      ref: 'refs/tags/v0.1.3',
    );
    final current = ProvenanceInfo(
      repository: 'https://github.com/mosuem/helpful',
      ref: 'refs/tags/v0.1.4',
    );

    expect(
      () => ProvenancePolicy.enforcePolicy(
        packageName: 'helpful',
        version: Version(0, 1, 4),
        currentProvenance: current,
        previousLockedProvenance: prev,
      ),
      returnsNormally,
    );
  });

  test('blocks downgrade attack when new version is unsigned', () {
    final prev = ProvenanceInfo(
      repository: 'https://github.com/mosuem/helpful',
      ref: 'refs/tags/v0.1.3',
    );

    expect(
      () => ProvenancePolicy.enforcePolicy(
        packageName: 'helpful',
        version: Version(0, 1, 4),
        currentProvenance: null,
        previousLockedProvenance: prev,
      ),
      throwsA(isA<PackageProvenanceException>()),
    );
  });

  test('detects repository switch when configured as fatal', () {
    final prev = ProvenanceInfo(
      repository: 'https://github.com/mosuem/helpful',
      ref: 'refs/tags/v0.1.3',
    );
    final current = ProvenanceInfo(
      repository: 'https://github.com/attacker/helpful',
      ref: 'refs/tags/v0.1.4',
    );

    expect(
      () => ProvenancePolicy.enforcePolicy(
        packageName: 'helpful',
        version: Version(0, 1, 4),
        currentProvenance: current,
        previousLockedProvenance: prev,
        fatalOnRepoMismatch: true,
      ),
      throwsA(isA<PackageProvenanceException>()),
    );
  });

  test('invokes onWarning when repository switch is non-fatal', () {
    final prev = ProvenanceInfo(
      repository: 'https://github.com/mosuem/helpful',
      ref: 'refs/tags/v0.1.3',
    );
    final current = ProvenanceInfo(
      repository: 'https://github.com/attacker/helpful',
      ref: 'refs/tags/v0.1.4',
    );

    var warningReceived = false;
    ProvenancePolicy.enforcePolicy(
      packageName: 'helpful',
      version: Version(0, 1, 4),
      currentProvenance: current,
      previousLockedProvenance: prev,
      fatalOnRepoMismatch: false,
      onWarning: (msg) {
        warningReceived = true;
      },
    );

    expect(warningReceived, isTrue);
  });
}
