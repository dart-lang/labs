import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

ffi.Pointer<ffi.Int> errnoPtr = malloc.allocate<ffi.Int>(1);
