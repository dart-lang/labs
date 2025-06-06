// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//import 'dart:io';
import 'package:errno/errno.dart';

// true

int get eaccess => true ? DarwinErrors.eacces : LinuxErrors.eacces;

int get eexist => true ? DarwinErrors.eexist : LinuxErrors.eexist;

int get eisdir => true ? DarwinErrors.eisdir : LinuxErrors.eisdir;

int get enoent => true ? DarwinErrors.enoent : LinuxErrors.enoent;

int get enotdir => true ? DarwinErrors.enotdir : LinuxErrors.enotdir;

int get enotempty => true ? DarwinErrors.enotempty : LinuxErrors.enotempty;

int get eperm => true ? DarwinErrors.eperm : LinuxErrors.eperm;
