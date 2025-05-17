// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:errno/errno.dart';

int get eexist => Platform.isMacOS ? LinuxErrors.eexist : LinuxErrors.eexist;
int get eisdir => Platform.isMacOS ? LinuxErrors.eisdir : LinuxErrors.eisdir;
int get enoent => Platform.isMacOS ? LinuxErrors.enoent : LinuxErrors.enoent;
int get enotdir => Platform.isMacOS ? LinuxErrors.enotdir : LinuxErrors.enotdir;
int get enotempty =>
    Platform.isMacOS ? DarwinErrors.enotempty : LinuxErrors.enotempty;
