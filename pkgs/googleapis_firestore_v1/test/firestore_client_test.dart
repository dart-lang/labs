// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:googleapis_firestore_v1/google/firestore/v1/firestore.pbgrpc.dart';
import 'package:test/test.dart';

void main() {
  group('FirestoreClient', () {
    test('has defaultHost', () {
      expect(FirestoreClient.defaultHost, isNotEmpty);
    });

    test('has oauthScopes', () {
      expect(FirestoreClient.oauthScopes, isNotEmpty);
    });
  });
}
