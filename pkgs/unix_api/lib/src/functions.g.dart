// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

import 'dart:ffi' as ffi;

import 'function_bindings.g.dart';
import 'errno.dart';

int open(ffi.Pointer<ffi.Char> arg0, int arg1, int arg2) {
  return libc_shim_open(arg0, arg1, arg2, errnoPtr);

}

int openat(int arg0, ffi.Pointer<ffi.Char> arg1, int arg2, int arg3) {
  return libc_shim_openat(arg0, arg1, arg2, arg3, errnoPtr);

}

int rename(ffi.Pointer<ffi.Char> arg0, ffi.Pointer<ffi.Char> arg1) {
  return libc_shim_rename(arg0, arg1, errnoPtr);

}

ffi.Pointer<ffi.Char> strerror(int arg0) {
  return libc_shim_strerror(arg0, errnoPtr);

}

int chmod(ffi.Pointer<ffi.Char> arg0, int arg1) {
  return libc_shim_chmod(arg0, arg1, errnoPtr);

}

int access(ffi.Pointer<ffi.Char> arg0, int arg1) {
  return libc_shim_access(arg0, arg1, errnoPtr);

}

int alarm(int arg0) {
  return libc_shim_alarm(arg0, errnoPtr);

}

int chdir(ffi.Pointer<ffi.Char> arg0) {
  return libc_shim_chdir(arg0, errnoPtr);

}

int close(int arg0) {
  return libc_shim_close(arg0, errnoPtr);

}

ffi.Pointer<ffi.Char> crypt(ffi.Pointer<ffi.Char> arg0, ffi.Pointer<ffi.Char> arg1) {
  return libc_shim_crypt(arg0, arg1, errnoPtr);

}

ffi.Pointer<ffi.Char> ctermid(ffi.Pointer<ffi.Char> arg0) {
  return libc_shim_ctermid(arg0, errnoPtr);

}

int dup(int arg0) {
  return libc_shim_dup(arg0, errnoPtr);

}

int dup2(int arg0, int arg1) {
  return libc_shim_dup2(arg0, arg1, errnoPtr);

}

int faccessat(int arg0, ffi.Pointer<ffi.Char> arg1, int arg2, int arg3) {
  return libc_shim_faccessat(arg0, arg1, arg2, arg3, errnoPtr);

}

int fchdir(int arg0) {
  return libc_shim_fchdir(arg0, errnoPtr);

}

int fdatasync(int arg0) {
  return libc_shim_fdatasync(arg0, errnoPtr);

}

ffi.Pointer<ffi.Char> getcwd(ffi.Pointer<ffi.Char> arg0, int arg1) {
  return libc_shim_getcwd(arg0, arg1, errnoPtr);

}

int getpid() {
  return libc_shim_getpid(errnoPtr);

}

int getppid() {
  return libc_shim_getppid(errnoPtr);

}

int read(int arg0, ffi.Pointer<ffi.Void> arg1, int arg2) {
  return libc_shim_read(arg0, arg1, arg2, errnoPtr);

}

int unlink(ffi.Pointer<ffi.Char> arg0) {
  return libc_shim_unlink(arg0, errnoPtr);

}

int unlinkat(int arg0, ffi.Pointer<ffi.Char> arg1, int arg2) {
  return libc_shim_unlinkat(arg0, arg1, arg2, errnoPtr);

}

