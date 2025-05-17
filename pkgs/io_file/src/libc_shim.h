// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A wrapper around libc that provides a consistent sent of types and symbols
// across platforms and architectures.
//
// libc is not required to provide runtime accessable symbols for POSIX calls.
// For example, glibc defines `stat` as:
//
// `#define stat(fname, buf) __xstat (_STAT_VER, fname, buf)`
//
// So running `ffigen` on `sys/stat.h` will not produce an entry for `stat`.
//
// libc may also reorder `struct` fields across architectures, add extra
// fields, etc.
//
// Finally, POSIX lets the implementation decide the type of many `struct`
// fields.
//
// `libc_shim.h` provides an interface that, when processed by `ffigen` will
// generate the same bindings on all platforms and architectures.
#include <stdint.h>

#define LIBC_SHIM_EXPORT                                                       \
  __attribute__((visibility("default"))) __attribute__((used))

// <dirent.h>

struct libc_shim_dirent {
  int64_t d_ino;
  char d_name[512];
};

typedef struct {
  struct libc_shim_dirent libc_shim_dirent;
  void *_dir;
} libc_shim_DIR;

LIBC_SHIM_EXPORT int libc_shim_closedir(libc_shim_DIR *d);
LIBC_SHIM_EXPORT libc_shim_DIR *libc_shim_opendir(const char *path);
LIBC_SHIM_EXPORT struct libc_shim_dirent *libc_shim_readdir(libc_shim_DIR *d);

// <errno.h>
LIBC_SHIM_EXPORT void libc_shim_seterrno(int err);
LIBC_SHIM_EXPORT int libc_shim_errno(void);

// <fcntl.h>
LIBC_SHIM_EXPORT int libc_shim_open(const char *pathname, int flags, int mode);

// <sys/stat.h>
struct libc_shim_timespec {
  int64_t tv_sec;
  int64_t tv_nsec;
};

struct libc_shim_Stat {
  int64_t st_dev;
  int64_t st_ino;
  int64_t st_mode;
  int64_t st_nlink;
  int64_t std_uid;
  int64_t st_size;

  struct libc_shim_timespec st_atim;
  struct libc_shim_timespec st_mtim;
  struct libc_shim_timespec st_ctim;
  // Only valid on macOS/iOS
  struct libc_shim_timespec st_btime;

  // Only valid on macOS/iOS
  int64_t st_flags;
};

LIBC_SHIM_EXPORT int libc_shim_mkdir(const char *pathname, int mode);
LIBC_SHIM_EXPORT int libc_shim_stat(const char *path,
                                    struct libc_shim_Stat *buf);
LIBC_SHIM_EXPORT int libc_shim_lstat(const char *path,
                                     struct libc_shim_Stat *buf);
LIBC_SHIM_EXPORT int libc_shim_fstat(int fd, struct libc_shim_Stat *buf);

// <stdio.h>
LIBC_SHIM_EXPORT int libc_shim_rename(const char *old, const char *newy);

// <stdlib.h>
LIBC_SHIM_EXPORT char *libc_shim_getenv(const char *name);
LIBC_SHIM_EXPORT char *libc_shim_mkdtemp(char *template);

// <string.h>

LIBC_SHIM_EXPORT char *libc_shim_strerror(int errnum);

// <unistd.h>

LIBC_SHIM_EXPORT int libc_shim_close(int fd);
LIBC_SHIM_EXPORT int libc_shim_unlinkat(int dirfd, const char *pathname,
                                        int flags);
