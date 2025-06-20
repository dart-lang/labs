// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'file_system.dart';
import 'native_posix_file_system.dart';
import 'vm_windows_file_system.dart';

/// Return the default [FileSystem] for the current platform.
FileSystem get fileSystem =>
    Platform.isWindows ? WindowsFileSystem() : NativePosixFileSystem();
