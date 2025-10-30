// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A wrapper around libc that provides a consistent set of types and symbols
// across platforms and architectures.
//
// libc is not required to provide runtime accessible symbols for POSIX calls.
// For example, glibc defines `stat` as:
//
// `#define stat(fname, buf) __xstat (_STAT_VER, fname, buf)`
//
// So running `ffigen` on `sys/stat.h` will not produce an entry for `stat`.
//
// libc may also reorder `struct` fields across architectures, add extra
// fields, etc. For example, the glibc definition of `struct stat` starts
// with:
//
// ```
// struct stat
//   {
//     __dev_t st_dev;		/* Device.  */
// #ifndef __x86_64__
//     unsigned short int __pad1;
// #endif
// #if defined __x86_64__ || !defined __USE_FILE_OFFSET64
//     __ino_t st_ino;		/* File serial number.	*/
// #else
// ```
//
// Finally, POSIX lets the implementation decide the type of many `struct`
// fields. In `struct stat`, the only requirement for the `dev_t` is that it
// be integral; there is no requirement on size or signedness.
//
// `libc_shim.h` provides an interface that, when processed by `ffigen`, will
// generate the same bindings on all platforms and architectures.
#include <stdint.h>

#define LIBC_SHIM_EXPORT                                                       \
  __attribute__((visibility("default"))) __attribute__((used))

// <dirent.h>

struct libc_shim_dirent {
  int64_t d_ino;     // POSIX
  uint8_t d_type;    // Linux, macOS/iOS
  char d_name[1025]; // POSIX; __DARWIN_MAXNAMLEN = 1024
};

typedef struct {
  struct libc_shim_dirent libc_shim_dirent;
  void *_dir;
} libc_shim_DIR;

// Returns `libc_shim_dirent.d_name`.
//
// TODO(brianquinlan): Remove `libc_shim_d_name_ptr` when there is a fix for:
// https://github.com/dart-lang/sdk/issues/41237
LIBC_SHIM_EXPORT char *libc_shim_d_name_ptr(struct libc_shim_dirent *d);
LIBC_SHIM_EXPORT int libc_shim_closedir(libc_shim_DIR *d, int *err);
LIBC_SHIM_EXPORT libc_shim_DIR *libc_shim_fdopendir(int fd, int *err);
LIBC_SHIM_EXPORT libc_shim_DIR *libc_shim_opendir(const char *path, int *err);
LIBC_SHIM_EXPORT struct libc_shim_dirent *libc_shim_readdir(libc_shim_DIR *d,
                                                            int *err);

// <pthread.h>

typedef struct {
  void *_pthread_t;
} libc_shim_pthread_t;

typedef struct {
  void *_pthread_attr_t;
} libc_shim_pthread_attr_t;

typedef struct {
  void *_pthread_mutex_t;
} libc_shim_pthread_mutex_t;

typedef struct {
  void *_pthread_mutexattr_t;
} libc_shim_pthread_mutexattr_t;

typedef struct {
  void *_pthread_cond_t;
} libc_shim_pthread_cond_t;

typedef struct {
  void *_pthread_condattr_t;
} libc_shim_pthread_condattr_t;

struct libc_shim_timespec;

LIBC_SHIM_EXPORT int
libc_shim_pthread_create(libc_shim_pthread_t *restrict thread,
                         const libc_shim_pthread_attr_t *restrict attr,
                         void *(*start_routine)(void *), void *restrict arg,
                         int *err);

LIBC_SHIM_EXPORT int libc_shim_pthread_detach(libc_shim_pthread_t thread, int *err);

LIBC_SHIM_EXPORT int
libc_shim_pthread_mutex_destroy(libc_shim_pthread_mutex_t *mutex, int *err);

LIBC_SHIM_EXPORT int
libc_shim_pthread_mutex_init(libc_shim_pthread_mutex_t *restrict mutex,
                             const libc_shim_pthread_mutexattr_t *restrict attr,
                             int *err);

LIBC_SHIM_EXPORT int
libc_shim_pthread_mutex_lock(libc_shim_pthread_mutex_t *mutex, int *err);

LIBC_SHIM_EXPORT int libc_shim_pthread_mutex_timedlock(
    libc_shim_pthread_mutex_t *restrict mutex,
    const struct libc_shim_timespec *restrict abs_timeout, int *err);

LIBC_SHIM_EXPORT int
libc_shim_pthread_mutex_unlock(libc_shim_pthread_mutex_t *mutex, int *err);

LIBC_SHIM_EXPORT int
libc_shim_pthread_cond_broadcast(libc_shim_pthread_cond_t *cond, int *err);

LIBC_SHIM_EXPORT int
libc_shim_pthread_cond_destroy(libc_shim_pthread_cond_t *cond, int *err);

LIBC_SHIM_EXPORT int
libc_shim_pthread_cond_init(libc_shim_pthread_cond_t *cond,
                            const libc_shim_pthread_condattr_t *attr, int *err);

LIBC_SHIM_EXPORT int libc_shim_pthread_cond_signal(libc_shim_pthread_cond_t *cond,
                                         int *err);

LIBC_SHIM_EXPORT int libc_shim_pthread_cond_timedwait(
    libc_shim_pthread_cond_t *cond, libc_shim_pthread_mutex_t *mutex,
    const struct libc_shim_timespec *abstime, int *err);
    
LIBC_SHIM_EXPORT int
libc_shim_pthread_cond_wait(libc_shim_pthread_cond_t *cond,
                            libc_shim_pthread_mutex_t *mutex, int *err);

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

LIBC_SHIM_EXPORT int libc_shim_stat(const char *path,
                                    struct libc_shim_Stat *buf, int *err);
LIBC_SHIM_EXPORT int libc_shim_lstat(const char *path,
                                     struct libc_shim_Stat *buf, int *err);
LIBC_SHIM_EXPORT int libc_shim_fstat(int fd, struct libc_shim_Stat *buf,
                                     int *err);
LIBC_SHIM_EXPORT int libc_shim_fstatat(int fd, char *path,
                                       struct libc_shim_Stat *buf, int flag,
                                       int *err);
