// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

String createTemp(String testName) =>
    Directory.systemTemp.createTempSync('move').absolute.path;
void deleteTemp(String path) => Directory(path).deleteSync(recursive: true);
