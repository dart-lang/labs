This package provides **experimental** bindings to POSIX APIs e.g. `open`,
`close`.

## Why have another POSIX API implementation for Dart?

There are two existing packages that provide POSIX API bindings for Dart:
1. [`package:posix`](https://pub.dev/packages/posix
2. [`package:stdlibc`]

Both are excellent and offer easier-to-use APIs than `package:unix_api`.

`package:unix_api` requires a native tool chain and has a small amount of
native code that cannot be tree shaken away. In exchange, it works on all
POSIX platforms that Dart supports.

In addition, `package:unix_api` implements `errno` in a way that makes it
independent of the operation of the Dart VM, e.g., if the Dart VM makes Unix
API calls as part of JIT compilation then the `errno` exported by
`package:unix_api` is not affected (see the Dart SDK issue
[Support for capturing errno across calls](https://github.com/dart-lang/sdk/issues/38832)).

| Package              | Required Tools   | Reliable `errno` | Supported Platforms                     | Fixed Disk Usage |
| :---                 | :--------------  | :--------------  | :-------------------------------------- | :--------------  |
|  [`package:posix`]   | Dart             | No               | iOS (arm64), Linux (x64), macOS (arm64) | 0 KiB            |
|  [`package:stdlibc`] | Dart             | No               | iOS (arm64), Linux (x64), macOS (arm64) | 0 KiB            |
|  `unix_api`          | Dart, C compiler | Yes              | Android (x64, arm32, arm64), iOS (arm64), Linux (x64, arm64), macOS (x64, arm64) | ~60 KiB |

## Design

The POSIX API is a defined in terms of source, not object compatibility.

For example, glibc defines `stat` using a macro:

`#define stat(fname, buf) __xstat (_STAT_VER, fname, buf)`

So using [`package:ffigen`] to generate Dart bindings for `sys/stat.h` will not
produce an entry for `stat`.

libc may also reorder `struct` fields across architectures, add extra
fields, etc. For example, the glibc definition of `struct stat` starts
with:

```c
struct stat
{
    __dev_t st_dev;		/* Device.  */
#ifndef __x86_64__
    unsigned short int __pad1;
#endif
#if defined __x86_64__ || !defined __USE_FILE_OFFSET64
    __ino_t st_ino;		/* File serial number.	*/
#else
```

When using [`package:ffigen`] to generate bindings for such code, seperate
bindings must be generated for every combination of platform (e.g. 
Android) and architecture (e.g. arm64).

`package:unix_api` works around this problem by defining a native (C) function
for every POSIX function. The native function just calls the corresponding
POSIX function while preserving `errno` by passing a reference to it explicitly.
For example:

```c
int libc_shim_rename(const char * arg0, const char * arg1, int * err) {
  int r;
  errno = *err;
  r = rename(arg0, arg1);
  *err = errno;
  return r;
}
```

This allows the platforms C compiler to deal with macro expansions,
platform-specific struct layout, etc. [`package:hooks'] is used to
transparently compile the C code on the developer's behalf.

Then `package:unix_api` uses `package:ffigen` to generate Dart bindings to
these functions. For example:

```dart
// ffigen'd bindings
@ffi.Native<
  ffi.Int Function(
    ffi.Pointer<ffi.Char>,
    ffi.Pointer<ffi.Char>,
    ffi.Pointer<ffi.Int>,
  )
>()
external int libc_shim_rename(
  ffi.Pointer<ffi.Char> arg0,
  ffi.Pointer<ffi.Char> arg1,
  ffi.Pointer<ffi.Int> arg2,
);
```

And finally, `package:unix_api` provides a function that provides the public
interface. For example:

```dart
/// Renames a file.
///
/// See the [POSIX specification for `rename`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/rename.html).
int rename(ffi.Pointer<ffi.Char> arg0, ffi.Pointer<ffi.Char> arg1) =>
    libc_shim_rename(arg0, arg1, errnoPtr);
```

`errno` is implemented [locally in the package](lib/src/errno.dart).

## Status: Experimental

**NOTE**: This package is currently experimental and published under the
[labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order to
solicit feedback. 

For packages in the labs.dart.dev publisher we generally plan to either graduate
the package into a supported publisher (dart.dev, tools.dart.dev) after a period
of feedback and iteration, or discontinue the package. These packages have a
much higher expected rate of API and breaking changes.

Your feedback is valuable and will help us evolve this package. For general
feedback, suggestions, and comments, please file an issue in the 
[bug tracker](https://github.com/dart-lang/labs/issues).

[`package:ffigen`]: https://pub.dev/packages/ffigen
[`package:hooks`]: https://pub.dev/packages/hooks
[`package:posix`]: https://pub.dev/packages/posix
[`package:stdlibc`]: https://pub.dev/packages/stdlibc
