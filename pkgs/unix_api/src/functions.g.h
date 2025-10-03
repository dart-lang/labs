// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

int libc_shim_valid_mode_t(long);

int libc_shim_valid_size_t(unsigned long);

__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_open(const char *, int, long, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_openat(int, const char *, int, long, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_rename(const char *, const char *, int *);


__attribute__((visibility("default"))) __attribute__((used))
char * libc_shim_strerror(int, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_chmod(const char *, long, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_access(const char *, int, int *);


__attribute__((visibility("default"))) __attribute__((used))
unsigned libc_shim_alarm(unsigned, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_chdir(const char *, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_close(int, int *);


__attribute__((visibility("default"))) __attribute__((used))
char * libc_shim_crypt(const char *, const char *, int *);


__attribute__((visibility("default"))) __attribute__((used))
char * libc_shim_ctermid(char *, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_dup(int, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_dup2(int, int, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_faccessat(int, const char *, int, int, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_fchdir(int, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_fdatasync(int, int *);


__attribute__((visibility("default"))) __attribute__((used))
char * libc_shim_getcwd(char *, unsigned long, int *);


__attribute__((visibility("default"))) __attribute__((used))
long libc_shim_getpid(int *);


__attribute__((visibility("default"))) __attribute__((used))
long libc_shim_getppid(int *);


__attribute__((visibility("default"))) __attribute__((used))
long libc_shim_read(int, void *, unsigned long, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_unlink(const char *, int *);


__attribute__((visibility("default"))) __attribute__((used))
int libc_shim_unlinkat(int, const char *, int, int *);


