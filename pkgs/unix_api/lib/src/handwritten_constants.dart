import 'dart:ffi' as ffi;

import 'package:unix_api/src/handwritten_constant_bindings.g.dart';

ffi.Pointer<ffi.Void> get MAP_FAILED {
  return libc_shim_get_MAP_FAILED();
}
