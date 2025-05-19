// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This library name is used by tests.
// ignore: unnecessary_library_directive, unnecessary_library_name
library gcloud.db.model_test.multiple_annotations;

import 'package:gcloud/db.dart' as db;

@db.Kind()
@db.Kind()
class A extends db.Model {}
