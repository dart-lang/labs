// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "libc_shim.h"

#include <assert.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

// <dirent.h>

char *libc_shim_d_name_ptr(struct libc_shim_dirent *d) { return d->d_name; }

int libc_shim_closedir(libc_shim_DIR *d, int *err) {
  errno = *err;
  int r = closedir(d->_dir);
  *err = errno;
  free(d);
  return r;
}

libc_shim_DIR *libc_shim_fdopendir(int fd, int *err) {
  errno = *err;
  DIR *d = fdopendir(fd);
  *err = errno;
  if (d == NULL) {
    return NULL;
  }
  libc_shim_DIR *myd = malloc(sizeof(libc_shim_DIR));
  myd->_dir = d;
  return myd;
}

libc_shim_DIR *libc_shim_opendir(const char *path, int *err) {
  errno = *err;
  DIR *d = opendir(path);
  *err = errno;
  if (d == NULL) {
    return NULL;
  }
  libc_shim_DIR *myd = malloc(sizeof(libc_shim_DIR));
  myd->_dir = d;
  return myd;
}

struct libc_shim_dirent *libc_shim_readdir(libc_shim_DIR *myd, int *err) {
  errno = *err;
  struct dirent *d = readdir(myd->_dir);
  *err = errno;
  if (d == NULL) {
    return NULL;
  }

  myd->libc_shim_dirent.d_ino = d->d_ino;
  myd->libc_shim_dirent.d_type = d->d_type;
  assert(strlen(myd->libc_shim_dirent.d_name) <
         sizeof(myd->libc_shim_dirent.d_name));
  strncpy(myd->libc_shim_dirent.d_name, d->d_name,
          sizeof(myd->libc_shim_dirent.d_name));
  return &(myd->libc_shim_dirent);
}

// <sys/stat.h>

static void _fill(struct libc_shim_Stat *buf, struct stat *s) {
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

int libc_shim_stat(const char *path, struct libc_shim_Stat *buf, int *err) {
  struct stat s;
  errno = *err;
  int r = stat(path, &s);
  *err = errno;
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

int libc_shim_lstat(const char *path, struct libc_shim_Stat *buf, int *err) {
  struct stat s;
  errno = *err;
  int r = lstat(path, &s);
  *err = errno;
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

int libc_shim_fstat(int fd, struct libc_shim_Stat *buf, int *err) {
  struct stat s;
  errno = *err;
  int r = fstat(fd, &s);
  *err = errno;
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

int libc_shim_fstatat(int fd, char *path, struct libc_shim_Stat *buf, int flag,
                      int *err) {
  struct stat s;
  errno = *err;
  int r = fstatat(fd, path, &s, flag);
  *err = errno;
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

// <pthread.h>

int libc_shim_pthread_create(libc_shim_pthread_t *restrict thread,
                             const libc_shim_pthread_attr_t *restrict attr,
                             void *(*start_routine)(void *), void *restrict arg,
                             int *err) {
  pthread_t *t = (pthread_t *)calloc(1, sizeof(pthread_t));
  errno = *err;
  int r = pthread_create(t, (attr == NULL) ? NULL : attr->_pthread_attr_t,
                         start_routine, arg);
  *err = errno;
  if (r == 0) {
    thread->_pthread_t = t;
  } else {
    free(t);
  }
  return r;
}

int libc_shim_pthread_detach(libc_shim_pthread_t thread, int *err) {
  errno = *err;
  int r = pthread_detach(*((pthread_t *)thread._pthread_t));
  *err = errno;
  free(thread._pthread_t);
  return r;

}

int libc_shim_pthread_mutex_destroy(libc_shim_pthread_mutex_t *mutex,
                                    int *err) {
  errno = *err;
  int r = pthread_mutex_destroy(mutex->_pthread_mutex_t);
  *err = errno;
  free(mutex->_pthread_mutex_t);
  return r;
}

int libc_shim_pthread_mutex_init(
    libc_shim_pthread_mutex_t *restrict mutex,
    const libc_shim_pthread_mutexattr_t *restrict attr, int *err) {
  pthread_mutex_t *m = (pthread_mutex_t *)calloc(1, sizeof(pthread_mutex_t));
  errno = *err;
  int r =
      pthread_mutex_init(m, (attr == NULL) ? NULL : attr->_pthread_mutexattr_t);
  *err = errno;
  if (r == 0) {
    mutex->_pthread_mutex_t = m;
  } else {
    free(m);
  }
  return r;
}

int libc_shim_pthread_mutex_lock(libc_shim_pthread_mutex_t *mutex, int *err) {
  errno = *err;
  int r = pthread_mutex_lock((pthread_mutex_t *) mutex->_pthread_mutex_t);
  *err = errno;
  return r;
}

int libc_shim_pthread_mutex_timedlock(
    libc_shim_pthread_mutex_t *restrict mutex,
    const struct libc_shim_timespec *restrict abs_timeout, int *err) {
#if defined(__linux__) || defined(__ANDROID__)

  struct timespec s;

  s.tv_nsec = abs_timeout->tv_nsec;
  s.tv_sec = abs_timeout->tv_sec;

  errno = *err;
  int r = pthread_mutex_timedlock((pthread_mutex_t *) mutex->_pthread_mutex_t, &s);
  *err = errno;
  return r;
#else
  return ENOSYS;
#endif
}

int libc_shim_pthread_mutex_unlock(libc_shim_pthread_mutex_t *mutex, int *err) {
  errno = *err;
  int r = pthread_mutex_unlock((pthread_mutex_t *) mutex->_pthread_mutex_t);
  *err = errno;
  return r;
}

int libc_shim_pthread_cond_broadcast(libc_shim_pthread_cond_t *cond, int *err) {
  errno = *err;
  int r = pthread_cond_broadcast((pthread_cond_t *) cond->_pthread_cond_t);
  *err = errno;
  return r;
}

int libc_shim_pthread_cond_destroy(libc_shim_pthread_cond_t *cond, int *err) {
  errno = *err;
  int r = pthread_cond_destroy((pthread_cond_t *) cond->_pthread_cond_t);
  *err = errno;
  free(cond->_pthread_cond_t);
  return r;
}

int libc_shim_pthread_cond_init(libc_shim_pthread_cond_t *cond,
                                const libc_shim_pthread_condattr_t *attr,
                                int *err) {
  pthread_cond_t *c = (pthread_cond_t *)calloc(1, sizeof(pthread_cond_t));
  errno = *err;
  int r =
      pthread_cond_init(c, (attr == NULL) ? NULL : (pthread_condattr_t *) attr->_pthread_condattr_t);
  *err = errno;
  if (r == 0) {
    cond->_pthread_cond_t = c;
  } else {
    free(c);
  }
  return r;
}

int libc_shim_pthread_cond_signal(libc_shim_pthread_cond_t *cond, int *err) {
  errno = *err;
  int r = pthread_cond_signal((pthread_cond_t *)cond->_pthread_cond_t);
  *err = errno;
  return r;
}

int libc_shim_pthread_cond_timedwait(libc_shim_pthread_cond_t *cond,
                                     libc_shim_pthread_mutex_t *mutex,
                                     const struct libc_shim_timespec *abstime,
                                     int *err) {
  struct timespec s;

  s.tv_nsec = abstime->tv_nsec;
  s.tv_sec = abstime->tv_sec;

  errno = *err;
  int r = pthread_cond_timedwait((pthread_cond_t *) cond->_pthread_cond_t, (pthread_mutex_t *) mutex->_pthread_mutex_t,
                                 &s);
  *err = errno;
  return r;
}

int libc_shim_pthread_cond_wait(libc_shim_pthread_cond_t *cond,
                                libc_shim_pthread_mutex_t *mutex, int *err) {
  errno = *err;
  int r = pthread_cond_wait((pthread_cond_t *) cond->_pthread_cond_t, (pthread_mutex_t *) mutex->_pthread_mutex_t);
  *err = errno;
  return r;
}
