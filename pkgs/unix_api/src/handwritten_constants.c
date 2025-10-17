// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <sys/mman.h>

#include "handwritten_constants.h"

void* libc_shim_get_MAP_FAILED(void) {
  return MAP_FAILED;
}
