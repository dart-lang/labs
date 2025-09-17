// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

#include <assert.h>
#include <errno.h>

#include "functions.g.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>
int libc_shim_rename(const char * arg0, const char * arg1) {
  return rename(arg0, arg1);
}

char * libc_shim_strerror(int arg0) {
  return strerror(arg0);
}

int libc_shim_access(const char * arg0, int arg1) {
  return access(arg0, arg1);
}

unsigned libc_shim_alarm(unsigned arg0) {
  return alarm(arg0);
}

int libc_shim_chdir(const char * arg0) {
  return chdir(arg0);
}

int libc_shim_close(int arg0) {
  return close(arg0);
}

char * libc_shim_crypt(const char * arg0, const char * arg1) {
#if defined(__ANDROID__)
  errno = ENOTSUP;
  return NULL;
#else
  return crypt(arg0, arg1);
#endif
}

char * libc_shim_ctermid(char * arg0) {
#if defined(__ANDROID__)
  errno = ENOTSUP;
  return "";
#else
  return ctermid(arg0);
#endif
}

int libc_shim_dup(int arg0) {
  return dup(arg0);
}

int libc_shim_dup2(int arg0, int arg1) {
  return dup2(arg0, arg1);
}

int libc_shim_faccessat(int arg0, const char * arg1, int arg2, int arg3) {
  return faccessat(arg0, arg1, arg2, arg3);
}

int libc_shim_fchdir(int arg0) {
  return fchdir(arg0);
}

int libc_shim_fdatasync(int arg0) {
#if defined(TARGET_OS_IOS)
  errno = ENOTSUP;
  return -1;
#else
  return fdatasync(arg0);
#endif
}

int libc_shim_unlink(const char * arg0) {
  return unlink(arg0);
}

int libc_shim_unlinkat(int arg0, const char * arg1, int arg2) {
  return unlinkat(arg0, arg1, arg2);
}

