// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_constants.dart`.

#include <assert.h>

#include "constants.g.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
int64_t libc_shim_get_DT_BLK(void) {
#ifdef DT_BLK
  assert(DT_BLK != libc_shim_UNDEFINED);
  return DT_BLK;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_DT_CHR(void) {
#ifdef DT_CHR
  assert(DT_CHR != libc_shim_UNDEFINED);
  return DT_CHR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_DT_DIR(void) {
#ifdef DT_DIR
  assert(DT_DIR != libc_shim_UNDEFINED);
  return DT_DIR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_DT_FIFO(void) {
#ifdef DT_FIFO
  assert(DT_FIFO != libc_shim_UNDEFINED);
  return DT_FIFO;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_DT_LNK(void) {
#ifdef DT_LNK
  assert(DT_LNK != libc_shim_UNDEFINED);
  return DT_LNK;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_DT_REG(void) {
#ifdef DT_REG
  assert(DT_REG != libc_shim_UNDEFINED);
  return DT_REG;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_DT_SOCK(void) {
#ifdef DT_SOCK
  assert(DT_SOCK != libc_shim_UNDEFINED);
  return DT_SOCK;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_DT_UNKNOWN(void) {
#ifdef DT_UNKNOWN
  assert(DT_UNKNOWN != libc_shim_UNDEFINED);
  return DT_UNKNOWN;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_EACCES(void) {
#ifdef EACCES
  assert(EACCES != libc_shim_UNDEFINED);
  return EACCES;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_EBADF(void) {
#ifdef EBADF
  assert(EBADF != libc_shim_UNDEFINED);
  return EBADF;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_EDOM(void) {
#ifdef EDOM
  assert(EDOM != libc_shim_UNDEFINED);
  return EDOM;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_EEXIST(void) {
#ifdef EEXIST
  assert(EEXIST != libc_shim_UNDEFINED);
  return EEXIST;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_EINTR(void) {
#ifdef EINTR
  assert(EINTR != libc_shim_UNDEFINED);
  return EINTR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_EINVAL(void) {
#ifdef EINVAL
  assert(EINVAL != libc_shim_UNDEFINED);
  return EINVAL;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_EMFILE(void) {
#ifdef EMFILE
  assert(EMFILE != libc_shim_UNDEFINED);
  return EMFILE;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_ENOENT(void) {
#ifdef ENOENT
  assert(ENOENT != libc_shim_UNDEFINED);
  return ENOENT;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_ENOSPC(void) {
#ifdef ENOSPC
  assert(ENOSPC != libc_shim_UNDEFINED);
  return ENOSPC;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_ENOSYS(void) {
#ifdef ENOSYS
  assert(ENOSYS != libc_shim_UNDEFINED);
  return ENOSYS;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_ENOTDIR(void) {
#ifdef ENOTDIR
  assert(ENOTDIR != libc_shim_UNDEFINED);
  return ENOTDIR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_ENOTEMPTY(void) {
#ifdef ENOTEMPTY
  assert(ENOTEMPTY != libc_shim_UNDEFINED);
  return ENOTEMPTY;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_EPERM(void) {
#ifdef EPERM
  assert(EPERM != libc_shim_UNDEFINED);
  return EPERM;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_ETIMEDOUT(void) {
#ifdef ETIMEDOUT
  assert(ETIMEDOUT != libc_shim_UNDEFINED);
  return ETIMEDOUT;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_AT_FDCWD(void) {
#ifdef AT_FDCWD
  assert(AT_FDCWD != libc_shim_UNDEFINED);
  return AT_FDCWD;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_AT_REMOVEDIR(void) {
#ifdef AT_REMOVEDIR
  assert(AT_REMOVEDIR != libc_shim_UNDEFINED);
  return AT_REMOVEDIR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_O_APPEND(void) {
#ifdef O_APPEND
  assert(O_APPEND != libc_shim_UNDEFINED);
  return O_APPEND;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_O_CLOEXEC(void) {
#ifdef O_CLOEXEC
  assert(O_CLOEXEC != libc_shim_UNDEFINED);
  return O_CLOEXEC;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_O_CREAT(void) {
#ifdef O_CREAT
  assert(O_CREAT != libc_shim_UNDEFINED);
  return O_CREAT;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_O_DIRECTORY(void) {
#ifdef O_DIRECTORY
  assert(O_DIRECTORY != libc_shim_UNDEFINED);
  return O_DIRECTORY;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_O_EXCL(void) {
#ifdef O_EXCL
  assert(O_EXCL != libc_shim_UNDEFINED);
  return O_EXCL;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_O_RDONLY(void) {
#ifdef O_RDONLY
  assert(O_RDONLY != libc_shim_UNDEFINED);
  return O_RDONLY;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_O_TRUNC(void) {
#ifdef O_TRUNC
  assert(O_TRUNC != libc_shim_UNDEFINED);
  return O_TRUNC;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_O_WRONLY(void) {
#ifdef O_WRONLY
  assert(O_WRONLY != libc_shim_UNDEFINED);
  return O_WRONLY;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_PATH_MAX(void) {
#ifdef PATH_MAX
  assert(PATH_MAX != libc_shim_UNDEFINED);
  return PATH_MAX;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_L_ctermid(void) {
#ifdef L_ctermid
  assert(L_ctermid != libc_shim_UNDEFINED);
  return L_ctermid;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_MAP_ANONYMOUS(void) {
#ifdef MAP_ANONYMOUS
  assert(MAP_ANONYMOUS != libc_shim_UNDEFINED);
  return MAP_ANONYMOUS;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_MAP_FIXED(void) {
#ifdef MAP_FIXED
  assert(MAP_FIXED != libc_shim_UNDEFINED);
  return MAP_FIXED;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_MAP_PRIVATE(void) {
#ifdef MAP_PRIVATE
  assert(MAP_PRIVATE != libc_shim_UNDEFINED);
  return MAP_PRIVATE;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_MAP_SHARED(void) {
#ifdef MAP_SHARED
  assert(MAP_SHARED != libc_shim_UNDEFINED);
  return MAP_SHARED;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_MCL_CURRENT(void) {
#ifdef MCL_CURRENT
  assert(MCL_CURRENT != libc_shim_UNDEFINED);
  return MCL_CURRENT;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_MCL_FUTURE(void) {
#ifdef MCL_FUTURE
  assert(MCL_FUTURE != libc_shim_UNDEFINED);
  return MCL_FUTURE;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_MS_ASYNC(void) {
#ifdef MS_ASYNC
  assert(MS_ASYNC != libc_shim_UNDEFINED);
  return MS_ASYNC;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_MS_INVALIDATE(void) {
#ifdef MS_INVALIDATE
  assert(MS_INVALIDATE != libc_shim_UNDEFINED);
  return MS_INVALIDATE;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_MS_SYNC(void) {
#ifdef MS_SYNC
  assert(MS_SYNC != libc_shim_UNDEFINED);
  return MS_SYNC;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_POSIX_MADV_DONTNEED(void) {
#ifdef POSIX_MADV_DONTNEED
  assert(POSIX_MADV_DONTNEED != libc_shim_UNDEFINED);
  return POSIX_MADV_DONTNEED;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_POSIX_MADV_NORMAL(void) {
#ifdef POSIX_MADV_NORMAL
  assert(POSIX_MADV_NORMAL != libc_shim_UNDEFINED);
  return POSIX_MADV_NORMAL;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_POSIX_MADV_RANDOM(void) {
#ifdef POSIX_MADV_RANDOM
  assert(POSIX_MADV_RANDOM != libc_shim_UNDEFINED);
  return POSIX_MADV_RANDOM;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_POSIX_MADV_SEQUENTIAL(void) {
#ifdef POSIX_MADV_SEQUENTIAL
  assert(POSIX_MADV_SEQUENTIAL != libc_shim_UNDEFINED);
  return POSIX_MADV_SEQUENTIAL;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_POSIX_MADV_WILLNEED(void) {
#ifdef POSIX_MADV_WILLNEED
  assert(POSIX_MADV_WILLNEED != libc_shim_UNDEFINED);
  return POSIX_MADV_WILLNEED;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_POSIX_TYPED_MEM_ALLOCATE(void) {
#ifdef POSIX_TYPED_MEM_ALLOCATE
  assert(POSIX_TYPED_MEM_ALLOCATE != libc_shim_UNDEFINED);
  return POSIX_TYPED_MEM_ALLOCATE;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_POSIX_TYPED_MEM_ALLOCATE_CONTIG(void) {
#ifdef POSIX_TYPED_MEM_ALLOCATE_CONTIG
  assert(POSIX_TYPED_MEM_ALLOCATE_CONTIG != libc_shim_UNDEFINED);
  return POSIX_TYPED_MEM_ALLOCATE_CONTIG;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_POSIX_TYPED_MEM_MAP_ALLOCATABLE(void) {
#ifdef POSIX_TYPED_MEM_MAP_ALLOCATABLE
  assert(POSIX_TYPED_MEM_MAP_ALLOCATABLE != libc_shim_UNDEFINED);
  return POSIX_TYPED_MEM_MAP_ALLOCATABLE;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_PROT_EXEC(void) {
#ifdef PROT_EXEC
  assert(PROT_EXEC != libc_shim_UNDEFINED);
  return PROT_EXEC;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_PROT_NONE(void) {
#ifdef PROT_NONE
  assert(PROT_NONE != libc_shim_UNDEFINED);
  return PROT_NONE;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_PROT_READ(void) {
#ifdef PROT_READ
  assert(PROT_READ != libc_shim_UNDEFINED);
  return PROT_READ;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_PROT_WRITE(void) {
#ifdef PROT_WRITE
  assert(PROT_WRITE != libc_shim_UNDEFINED);
  return PROT_WRITE;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_AT_SYMLINK_NOFOLLOW(void) {
#ifdef AT_SYMLINK_NOFOLLOW
  assert(AT_SYMLINK_NOFOLLOW != libc_shim_UNDEFINED);
  return AT_SYMLINK_NOFOLLOW;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_AT_RESOLVE_BENEATH(void) {
#ifdef AT_RESOLVE_BENEATH
  assert(AT_RESOLVE_BENEATH != libc_shim_UNDEFINED);
  return AT_RESOLVE_BENEATH;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_AT_EMPTY_PATH(void) {
#ifdef AT_EMPTY_PATH
  assert(AT_EMPTY_PATH != libc_shim_UNDEFINED);
  return AT_EMPTY_PATH;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IEXEC(void) {
#ifdef S_IEXEC
  assert(S_IEXEC != libc_shim_UNDEFINED);
  return S_IEXEC;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IFBLK(void) {
#ifdef S_IFBLK
  assert(S_IFBLK != libc_shim_UNDEFINED);
  return S_IFBLK;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IFCHR(void) {
#ifdef S_IFCHR
  assert(S_IFCHR != libc_shim_UNDEFINED);
  return S_IFCHR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IFDIR(void) {
#ifdef S_IFDIR
  assert(S_IFDIR != libc_shim_UNDEFINED);
  return S_IFDIR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IFIFO(void) {
#ifdef S_IFIFO
  assert(S_IFIFO != libc_shim_UNDEFINED);
  return S_IFIFO;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IFLNK(void) {
#ifdef S_IFLNK
  assert(S_IFLNK != libc_shim_UNDEFINED);
  return S_IFLNK;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IFMT(void) {
#ifdef S_IFMT
  assert(S_IFMT != libc_shim_UNDEFINED);
  return S_IFMT;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IFREG(void) {
#ifdef S_IFREG
  assert(S_IFREG != libc_shim_UNDEFINED);
  return S_IFREG;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IFSOCK(void) {
#ifdef S_IFSOCK
  assert(S_IFSOCK != libc_shim_UNDEFINED);
  return S_IFSOCK;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IFWHT(void) {
#ifdef S_IFWHT
  assert(S_IFWHT != libc_shim_UNDEFINED);
  return S_IFWHT;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IREAD(void) {
#ifdef S_IREAD
  assert(S_IREAD != libc_shim_UNDEFINED);
  return S_IREAD;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IRGRP(void) {
#ifdef S_IRGRP
  assert(S_IRGRP != libc_shim_UNDEFINED);
  return S_IRGRP;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IROTH(void) {
#ifdef S_IROTH
  assert(S_IROTH != libc_shim_UNDEFINED);
  return S_IROTH;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IRUSR(void) {
#ifdef S_IRUSR
  assert(S_IRUSR != libc_shim_UNDEFINED);
  return S_IRUSR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IRWXG(void) {
#ifdef S_IRWXG
  assert(S_IRWXG != libc_shim_UNDEFINED);
  return S_IRWXG;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IRWXO(void) {
#ifdef S_IRWXO
  assert(S_IRWXO != libc_shim_UNDEFINED);
  return S_IRWXO;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IRWXU(void) {
#ifdef S_IRWXU
  assert(S_IRWXU != libc_shim_UNDEFINED);
  return S_IRWXU;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_ISGID(void) {
#ifdef S_ISGID
  assert(S_ISGID != libc_shim_UNDEFINED);
  return S_ISGID;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_ISTXT(void) {
#ifdef S_ISTXT
  assert(S_ISTXT != libc_shim_UNDEFINED);
  return S_ISTXT;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_ISUID(void) {
#ifdef S_ISUID
  assert(S_ISUID != libc_shim_UNDEFINED);
  return S_ISUID;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_ISVTX(void) {
#ifdef S_ISVTX
  assert(S_ISVTX != libc_shim_UNDEFINED);
  return S_ISVTX;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IWGRP(void) {
#ifdef S_IWGRP
  assert(S_IWGRP != libc_shim_UNDEFINED);
  return S_IWGRP;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IWOTH(void) {
#ifdef S_IWOTH
  assert(S_IWOTH != libc_shim_UNDEFINED);
  return S_IWOTH;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IWRITE(void) {
#ifdef S_IWRITE
  assert(S_IWRITE != libc_shim_UNDEFINED);
  return S_IWRITE;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IWUSR(void) {
#ifdef S_IWUSR
  assert(S_IWUSR != libc_shim_UNDEFINED);
  return S_IWUSR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IXGRP(void) {
#ifdef S_IXGRP
  assert(S_IXGRP != libc_shim_UNDEFINED);
  return S_IXGRP;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IXOTH(void) {
#ifdef S_IXOTH
  assert(S_IXOTH != libc_shim_UNDEFINED);
  return S_IXOTH;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_S_IXUSR(void) {
#ifdef S_IXUSR
  assert(S_IXUSR != libc_shim_UNDEFINED);
  return S_IXUSR;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_UF_APPEND(void) {
#ifdef UF_APPEND
  assert(UF_APPEND != libc_shim_UNDEFINED);
  return UF_APPEND;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_UF_HIDDEN(void) {
#ifdef UF_HIDDEN
  assert(UF_HIDDEN != libc_shim_UNDEFINED);
  return UF_HIDDEN;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_F_OK(void) {
#ifdef F_OK
  assert(F_OK != libc_shim_UNDEFINED);
  return F_OK;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_R_OK(void) {
#ifdef R_OK
  assert(R_OK != libc_shim_UNDEFINED);
  return R_OK;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_W_OK(void) {
#ifdef W_OK
  assert(W_OK != libc_shim_UNDEFINED);
  return W_OK;
#endif
  return libc_shim_UNDEFINED;
}
int64_t libc_shim_get_X_OK(void) {
#ifdef X_OK
  assert(X_OK != libc_shim_UNDEFINED);
  return X_OK;
#endif
  return libc_shim_UNDEFINED;
}
