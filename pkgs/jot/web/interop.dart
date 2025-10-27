// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:js/js.dart' as js;

@JS('Response')
@js.staticInterop
class FetchResponse {}

extension FetchResponseExtension on FetchResponse {
  external int get status;

  // JSPromise<String>
  external JSPromise text();
}
