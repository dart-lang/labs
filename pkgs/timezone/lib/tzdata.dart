// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// Library to work with [tzdata](http://en.wikipedia.org/wiki/Tz_database)
///
/// - Zic compiled zone files
/// - zone.tab
library timezone.tzdata;

import 'dart:convert';
import 'dart:collection';
import 'dart:typed_data';

part 'package:timezone/src/tzdata/zicfile.dart';
part 'package:timezone/src/tzdata/zone_tab.dart';
