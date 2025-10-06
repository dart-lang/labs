// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

import 'dart:ffi' as ffi;

import 'function_bindings.g.dart';
import 'errno.dart';

/// Opens a file.
///
/// See the [POSIX specification for `open`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/open.html).
int open(ffi.Pointer<ffi.Char> arg0, int arg1, int arg2) =>
    libc_shim_open(arg0, arg1, arg2, errnoPtr);

/// Opens a file relative to a file descriptor.
///
/// See the [POSIX specification for `openat`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/openat.html).
int openat(int arg0, ffi.Pointer<ffi.Char> arg1, int arg2, int arg3) =>
    libc_shim_openat(arg0, arg1, arg2, arg3, errnoPtr);

/// Renames a file.
///
/// See the [POSIX specification for `rename`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/rename.html).
int rename(ffi.Pointer<ffi.Char> arg0, ffi.Pointer<ffi.Char> arg1) =>
    libc_shim_rename(arg0, arg1, errnoPtr);

/// Create a temporary directory.
///
/// See the [POSIX specification for `mkdtemp`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/mkdtemp.html).
ffi.Pointer<ffi.Char> mkdtemp(ffi.Pointer<ffi.Char> arg0) =>
    libc_shim_mkdtemp(arg0, errnoPtr);

/// Gets the value of an environment variable.
///
/// See the [POSIX specification for `getenv`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/getenv.html).
ffi.Pointer<ffi.Char> getenv(ffi.Pointer<ffi.Char> arg0) =>
    libc_shim_getenv(arg0, errnoPtr);

/// Formats an error code as a string.
///
/// See the [POSIX specification for `strerror`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/strerror.html).
ffi.Pointer<ffi.Char> strerror(int arg0) => libc_shim_strerror(arg0, errnoPtr);

/// Changes the mode of a file.
///
/// See the [POSIX specification for `chmod`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/chmod.html).
int chmod(ffi.Pointer<ffi.Char> arg0, int arg1) =>
    libc_shim_chmod(arg0, arg1, errnoPtr);

/// Creates a directory
///
/// See the [POSIX specification for `mkdir`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/mkdir.html).
int mkdir(ffi.Pointer<ffi.Char> arg0, int arg1) =>
    libc_shim_mkdir(arg0, arg1, errnoPtr);

/// Determines the accessibility of a file.
///
/// See the [POSIX specification for `access`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/access.html).
int access(ffi.Pointer<ffi.Char> arg0, int arg1) =>
    libc_shim_access(arg0, arg1, errnoPtr);

/// Schedules an alarm signal.
///
/// See the [POSIX specification for `alarm`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/alarm.html).
int alarm(int arg0) => libc_shim_alarm(arg0, errnoPtr);

/// Changes the working directory.
///
/// See the [POSIX specification for `chdir`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/chdir.html).
int chdir(ffi.Pointer<ffi.Char> arg0) => libc_shim_chdir(arg0, errnoPtr);

/// Closes a file descriptor.
///
/// See the [POSIX specification for `close`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/close.html).
int close(int arg0) => libc_shim_close(arg0, errnoPtr);

/// Encrypts a string.
///
/// See the [POSIX specification for `crypt`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/crypt.html).
ffi.Pointer<ffi.Char> crypt(
  ffi.Pointer<ffi.Char> arg0,
  ffi.Pointer<ffi.Char> arg1,
) => libc_shim_crypt(arg0, arg1, errnoPtr);

/// Generates a path name for the controlling terminal.
///
/// See the [POSIX specification for `ctermid`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/ctermid.html).
ffi.Pointer<ffi.Char> ctermid(ffi.Pointer<ffi.Char> arg0) =>
    libc_shim_ctermid(arg0, errnoPtr);

/// Duplicates an open file descriptor.
///
/// See the [POSIX specification for `dup`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/dup.html).
int dup(int arg0) => libc_shim_dup(arg0, errnoPtr);

/// Copies an open file descriptor into another.
///
/// See the [POSIX specification for `dup2`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/dup.html).
int dup2(int arg0, int arg1) => libc_shim_dup2(arg0, arg1, errnoPtr);

/// Determines the accessibility of a file descriptor.
///
/// See the [POSIX specification for `faccessat`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/faccessat.html).
int faccessat(int arg0, ffi.Pointer<ffi.Char> arg1, int arg2, int arg3) =>
    libc_shim_faccessat(arg0, arg1, arg2, arg3, errnoPtr);

/// Changes the current directory.
///
/// See the [POSIX specification for `fchdir`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/fchdir.html).
int fchdir(int arg0) => libc_shim_fchdir(arg0, errnoPtr);

/// Forces all queued I/O operations to complete.
///
/// See the [POSIX specification for `fdatasync`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/fdatasync.html).
int fdatasync(int arg0) => libc_shim_fdatasync(arg0, errnoPtr);

/// Gets the current working directory.
///
/// See the [POSIX specification for `getcwd`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/getcwd.html).
ffi.Pointer<ffi.Char> getcwd(ffi.Pointer<ffi.Char> arg0, int arg1) =>
    libc_shim_getcwd(arg0, arg1, errnoPtr);

/// Gets the current process id.
///
/// See the [POSIX specification for `getpid`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpid.html).
int getpid() => libc_shim_getpid(errnoPtr);

/// Gets the parent process id.
///
/// See the [POSIX specification for `getppid`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/getppid.html).
int getppid() => libc_shim_getppid(errnoPtr);

/// Reads from a file.
///
/// See the [POSIX specification for `read`](https://pubs.opengroup.org/onlinepubs/009696699/functions/read.html).
int read(int arg0, ffi.Pointer<ffi.Void> arg1, int arg2) =>
    libc_shim_read(arg0, arg1, arg2, errnoPtr);

/// Writes to a file.
///
/// See the [POSIX specification for `write`](https://pubs.opengroup.org/onlinepubs/009696699/functions/write.html).
int write(int arg0, ffi.Pointer<ffi.Void> arg1, int arg2) =>
    libc_shim_write(arg0, arg1, arg2, errnoPtr);

/// Removes a directory entry.
///
/// See the [POSIX specification for `unlink`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/linkat.html).
int unlink(ffi.Pointer<ffi.Char> arg0) => libc_shim_unlink(arg0, errnoPtr);

/// Removes a directory entry relative to another file.
///
/// See the [POSIX specification for `unlinkat`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/unlinkat.html).
int unlinkat(int arg0, ffi.Pointer<ffi.Char> arg1, int arg2) =>
    libc_shim_unlinkat(arg0, arg1, arg2, errnoPtr);
