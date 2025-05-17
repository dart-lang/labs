// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "libc_shim.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

// <dirent.h>

int my_closedir(my_DIR *d) {
  int r = closedir(d->_dir);
  free(d);
  return r;
}

my_DIR *my_opendir(const char *path) {
  my_DIR *myd = malloc(sizeof(my_DIR));

  DIR *d = opendir(path);
  if (d == NULL) {
    return NULL;
  }
  myd->_dir = d;
  return myd;
}

struct my_dirent *my_readdir(my_DIR *myd) {
  struct dirent *d = readdir(myd->_dir);
  if (d == NULL) {
    return NULL;
  }

  myd->my_dirent.d_ino = d->d_ino;
  strncpy(myd->my_dirent.d_name, d->d_name, sizeof(myd->my_dirent.d_name));
  return &(myd->my_dirent);
}

// <errno.h>

void my_seterrno(int err) { errno = err; }

int my_errno(void) { return errno; }

// <fcntl.h>

int my_open(const char *pathname, int flags, int mode) {
  return open(pathname, flags, mode);
}

// <sys/stat.h>

static void _fill(struct my_Stat *buf, struct stat *s) {
  buf->st_dev = s->st_dev;
  buf->st_ino = s->st_ino;
  buf->st_mode = s->st_mode;
  buf->st_nlink = s->st_nlink;
  buf->std_uid = s->st_uid;
  buf->st_size = s->st_size;
#ifdef __APPLE__
  buf->st_atim.tv_sec = s->st_atimespec.tv_sec;
  buf->st_atim.tv_nsec = s->st_atimespec.tv_nsec;

  buf->st_ctim.tv_sec = s->st_ctimespec.tv_sec;
  buf->st_ctim.tv_nsec = s->st_ctimespec.tv_nsec;

  buf->st_mtim.tv_sec = s->st_mtimespec.tv_sec;
  buf->st_mtim.tv_nsec = s->st_mtimespec.tv_nsec;

  buf->st_btime.tv_sec = s->st_birthtimespec.tv_sec;
  buf->st_btime.tv_nsec = s->st_birthtimespec.tv_nsec;

  buf->st_flags = s->st_flags;
#elif __linux__
  // https://man7.org/linux/man-pages/man3/stat.3type.html

  buf->st_atim.tv_sec = s->st_atim.tv_sec;
  buf->st_atim.tv_nsec = s->st_atim.tv_nsec;

  buf->st_ctim.tv_sec = s->st_ctim.tv_sec;
  buf->st_ctim.tv_nsec = s->st_ctim.tv_nsec;

  buf->st_mtim.tv_sec = s->st_mtim.tv_sec;
  buf->st_mtim.tv_nsec = s->st_mtim.tv_nsec;
#endif
}

int my_mkdir(const char *pathname, int mode) {
  return mkdir(pathname, mode);
}

int my_stat(const char *path, struct my_Stat *buf) {
  struct stat s;
  int r = stat(path, &s);
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

int my_lstat(const char *path, struct my_Stat *buf) {
  struct stat s;
  int r = lstat(path, &s);
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

int my_fstat(int fd, struct my_Stat *buf) {
  struct stat s;
  int r = fstat(fd, &s);
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

// <stdio.h>

int my_rename(const char *old, const char *newy) { return rename(old, newy); }

// <stdlib.h>

char *my_getenv(const char *name) { return getenv(name); }

char *my_mkdtemp(char *template) { return mkdtemp(template); }

// <string.h>

char *my_strerror(int errnum) { return strerror(errnum); }

// <unistd.h>

int my_close(int fd) { return close(fd); }

int my_unlinkat(int dirfd, const char *pathname, int flags) {
  return unlinkat(dirfd, pathname, flags);
}
