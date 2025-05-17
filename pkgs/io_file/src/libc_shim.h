// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdint.h>

#define MYLIB_EXPORT                                                           \
  __attribute__((visibility("default"))) __attribute__((used))

// <dirent.h>

struct my_dirent {
  int64_t d_ino;
  char d_name[512];
};

typedef struct {
  struct my_dirent my_dirent;
  void *_dir;
} my_DIR;

MYLIB_EXPORT int my_closedir(my_DIR *d);
MYLIB_EXPORT my_DIR *my_opendir(const char *path);
MYLIB_EXPORT struct my_dirent *my_readdir(my_DIR *d);

// <errno.h>
MYLIB_EXPORT void my_seterrno(int err);
MYLIB_EXPORT int my_errno(void);

// <fcntl.h>
MYLIB_EXPORT int my_open(const char *pathname, int flags, int mode);

// <sys/stat.h>
struct my_timespec {
  int64_t tv_sec;
  int64_t tv_nsec;
};

struct my_Stat {
  int64_t st_dev;
  int64_t st_ino;
  int64_t st_mode;
  int64_t st_nlink;
  int64_t std_uid;
  int64_t st_size;

  struct my_timespec st_atim;
  struct my_timespec st_mtim;
  struct my_timespec st_ctim;
  // Only valid on macOS/iOS
  struct my_timespec st_btime;

  // Only valid on macOS/iOS
  int64_t st_flags;
};

MYLIB_EXPORT int my_mkdir(const char *pathname, int mode);
MYLIB_EXPORT int my_stat(const char *path, struct my_Stat *buf);
MYLIB_EXPORT int my_lstat(const char *path, struct my_Stat *buf);
MYLIB_EXPORT int my_fstat(int fd, struct my_Stat *buf);

// <stdio.h>
MYLIB_EXPORT int my_rename(const char *old, const char *newy);

// <stdlib.h>
MYLIB_EXPORT char *my_getenv(const char *name);
MYLIB_EXPORT char *my_mkdtemp(char *template);

// <string.h>

MYLIB_EXPORT char *my_strerror(int errnum);

// <unistd.h>

MYLIB_EXPORT int my_close(int fd);
MYLIB_EXPORT int my_unlinkat(int dirfd, const char *pathname, int flags);
