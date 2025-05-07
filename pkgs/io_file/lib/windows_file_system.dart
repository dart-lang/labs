// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'src/vm_windows_file_system.dart'
    show WindowsFileSystem, deleteDirectoryRecursively
    if (dart.library.html) 'src/web_windows_file_system.dart'
    show WindowsFileSystem;
