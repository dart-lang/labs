// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

/// Determines the accessibility of a file.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/access.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
int libc_shim_access(const char *, int);


/// Schedules an alarm signal.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/alarm.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
unsigned libc_shim_alarm(unsigned);


/// Changes the working directory.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/chdir.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
int libc_shim_chdir(const char *);


/// Closes a file descriptor.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/close.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
int libc_shim_close(int);


/// Encrypts a string.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/crypt.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
char * libc_shim_crypt(const char *, const char *);


/// Generates a path name for the controlling terminal.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/ctermid.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
char * libc_shim_ctermid(char *);


/// Duplicates an open file descriptor.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/dup.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
int libc_shim_dup(int);


/// Copies an open file descriptor into another.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/dup.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
int libc_shim_dup2(int, int);


/// Determines the accessibility of a file descriptor.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/faccessat.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
int libc_shim_faccessat(int, const char *, int, int);


/// Changes the current directory.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/fchdir.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
int libc_shim_fchdir(int);


/// Forces all queued I/O operations to complete.
///
/// Read the [specification](https://pubs.opengroup.org/onlinepubs/9699919799/functions/fdatasync.html). 
/// __attribute__((visibility("default"))) __attribute__((used))
int libc_shim_fdatasync(int);


