// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

#include <assert.h>
#include <errno.h>

#include "functions.g.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
int libc_shim_valid_mode_t(long a) { return (long)((mode_t) a) == a; }

int libc_shim_valid_size_t(unsigned long a) { return (unsigned long)((size_t) a) == a; }

int libc_shim_open(const char * arg0, int arg1, long arg2, int * err) {
  if (!libc_shim_valid_mode_t(arg2)) {
    *err = EDOM;
    return -1;
  }
  errno = *err;
  int r = open(arg0, arg1, (mode_t) arg2);
  *err = errno;
  return r;
}


int libc_shim_openat(int arg0, const char * arg1, int arg2, long arg3, int * err) {
  if (!libc_shim_valid_mode_t(arg3)) {
    *err = EDOM;
    return -1;
  }
  errno = *err;
  int r = openat(arg0, arg1, arg2, (mode_t) arg3);
  *err = errno;
  return r;
}


int libc_shim_rename(const char * arg0, const char * arg1, int * err) {
  errno = *err;
  int r = rename(arg0, arg1);
  *err = errno;
  return r;
}


char * libc_shim_mkdtemp(char * arg0, int * err) {
  errno = *err;
  char * r = mkdtemp(arg0);
  *err = errno;
  return r;
}


char * libc_shim_getenv(const char * arg0, int * err) {
  errno = *err;
  char * r = getenv(arg0);
  *err = errno;
  return r;
}


char * libc_shim_strerror(int arg0, int * err) {
  errno = *err;
  char * r = strerror(arg0);
  *err = errno;
  return r;
}


int libc_shim_chmod(const char * arg0, long arg1, int * err) {
  if (!libc_shim_valid_mode_t(arg1)) {
    *err = EDOM;
    return -1;
  }
  errno = *err;
  int r = chmod(arg0, (mode_t) arg1);
  *err = errno;
  return r;
}


int libc_shim_mkdir(const char * arg0, long arg1, int * err) {
  if (!libc_shim_valid_mode_t(arg1)) {
    *err = EDOM;
    return -1;
  }
  errno = *err;
  int r = mkdir(arg0, (mode_t) arg1);
  *err = errno;
  return r;
}


int libc_shim_access(const char * arg0, int arg1, int * err) {
  errno = *err;
  int r = access(arg0, arg1);
  *err = errno;
  return r;
}


unsigned libc_shim_alarm(unsigned arg0, int * err) {
  errno = *err;
  unsigned r = alarm(arg0);
  *err = errno;
  return r;
}


int libc_shim_chdir(const char * arg0, int * err) {
  errno = *err;
  int r = chdir(arg0);
  *err = errno;
  return r;
}


int libc_shim_close(int arg0, int * err) {
  errno = *err;
  int r = close(arg0);
  *err = errno;
  return r;
}


char * libc_shim_crypt(const char * arg0, const char * arg1, int * err) {
#if defined(__ANDROID__)
  *err = ENOSYS;
  return NULL;
#else
  errno = *err;
  char * r = crypt(arg0, arg1);
  *err = errno;
  return r;
#endif
}


char * libc_shim_ctermid(char * arg0, int * err) {
#if defined(__ANDROID__)
  *err = ENOSYS;
  return "";
#else
  errno = *err;
  char * r = ctermid(arg0);
  *err = errno;
  return r;
#endif
}


int libc_shim_dup(int arg0, int * err) {
  errno = *err;
  int r = dup(arg0);
  *err = errno;
  return r;
}


int libc_shim_dup2(int arg0, int arg1, int * err) {
  errno = *err;
  int r = dup2(arg0, arg1);
  *err = errno;
  return r;
}


int libc_shim_faccessat(int arg0, const char * arg1, int arg2, int arg3, int * err) {
  errno = *err;
  int r = faccessat(arg0, arg1, arg2, arg3);
  *err = errno;
  return r;
}


int libc_shim_fchdir(int arg0, int * err) {
  errno = *err;
  int r = fchdir(arg0);
  *err = errno;
  return r;
}


int libc_shim_fdatasync(int arg0, int * err) {
#if defined(TARGET_OS_IOS)
  *err = ENOSYS;
  return -1;
#else
  errno = *err;
  int r = fdatasync(arg0);
  *err = errno;
  return r;
#endif
}


char * libc_shim_getcwd(char * arg0, unsigned long arg1, int * err) {
  if (!libc_shim_valid_size_t(arg1)) {
    *err = EDOM;
    return NULL;
  }
  errno = *err;
  char * r = getcwd(arg0, (size_t) arg1);
  *err = errno;
  return r;
}


long libc_shim_getpid(int * err) {
  errno = *err;
  pid_t r = getpid();
  *err = errno;
  if ((pid_t)((long) r) != r) {
    errno = ERANGE;
    return -1;
  }  
  return r;
}


long libc_shim_getppid(int * err) {
  errno = *err;
  pid_t r = getppid();
  *err = errno;
  if ((pid_t)((long) r) != r) {
    errno = ERANGE;
    return -1;
  }  
  return r;
}


long libc_shim_read(int arg0, void * arg1, unsigned long arg2, int * err) {
  if (!libc_shim_valid_size_t(arg2)) {
    *err = EDOM;
    return -1;
  }
  errno = *err;
  ssize_t r = read(arg0, arg1, (size_t) arg2);
  *err = errno;
  if ((ssize_t)((long) r) != r) {
    errno = ERANGE;
    return -1;
  }  
  return r;
}


long libc_shim_write(int arg0, const void * arg1, unsigned long arg2, int * err) {
  if (!libc_shim_valid_size_t(arg2)) {
    *err = EDOM;
    return -1;
  }
  errno = *err;
  ssize_t r = write(arg0, arg1, (size_t) arg2);
  *err = errno;
  if ((ssize_t)((long) r) != r) {
    errno = ERANGE;
    return -1;
  }  
  return r;
}


int libc_shim_unlink(const char * arg0, int * err) {
  errno = *err;
  int r = unlink(arg0);
  *err = errno;
  return r;
}


int libc_shim_unlinkat(int arg0, const char * arg1, int arg2, int * err) {
  errno = *err;
  int r = unlinkat(arg0, arg1, arg2);
  *err = errno;
  return r;
}


