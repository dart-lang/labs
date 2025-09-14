// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

#include <assert.h>

#include "functions.g.h"

#include <stdio.h>
#include <string.h>
#include <unistd.h>
int libc_shim_rename(const char * a, const char * b) {
  return rename(a, b);
}

char * libc_shim_strerror(int a) {
  return strerror(a);
}

int libc_shim_access(const char * a, int b) {
  return access(a, b);
}

unsigned libc_shim_alarm(unsigned a) {
  return alarm(a);
}

int libc_shim_chdir(const char * a) {
  return chdir(a);
}

int libc_shim_close(int a) {
  return close(a);
}

char * libc_shim_crypt(const char * a, const char * b) {
  return crypt(a, b);
}

char * libc_shim_ctermid(char * a) {
  return ctermid(a);
}

int libc_shim_dup(int a) {
  return dup(a);
}

int libc_shim_dup2(int a, int b) {
  return dup2(a, b);
}

int libc_shim_faccessat(int a, const char * b, int c, int d) {
  return faccessat(a, b, c, d);
}

int libc_shim_fchdir(int a) {
  return fchdir(a);
}

int libc_shim_fdatasync(int a) {
  return fdatasync(a);
}

int libc_shim_unlink(const char *path) {
  return unlink(path);
}

int libc_shim_unlinkat(int a, const char * b, int c) {
  return unlinkat(a, b, c);
}

