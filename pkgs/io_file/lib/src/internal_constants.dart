// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The maximum number of bytes to read in a single call to `read`.
//
// On macOS, it is an error to call
// `read/_read(fildes, buf, nbyte)` with `nbyte >= INT_MAX`.
//
// The POSIX specification states that the behavior of `read` is
// implementation-defined if `nbyte > SSIZE_MAX`. On Linux, the `read` will
// transfer at most 0x7ffff000 bytes and return the number of bytes actually.
// transfered.
//
// A smaller value has the advantage of making vm-service clients
// (e.g. debugger) more responsive.
//
// A bigger value reduces the number of system calls.
const int maxReadSize = 16 * 1024 * 1024; // 16MB.

// If the size of a file is unknown, read in blocks of this size.
const int blockSize = 64 * 1024;
