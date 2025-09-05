This package provides **experimental** bindings to POSIX APIs e.g. `open`, `close`.

## Why have another POSIX API implementation for Dart?

| Package               | Requires Toolchain | Fixed  | iOS   | macOS | Windows | Fake POSIX | Fake Windows |
| :---                  |  :---:  | :---: | :---: | :---: | :----:  | :--------: | :----------: | 
|  canonicalize path    |         |       |       |       |         |            |              |


Thare are two existing packages that provide POSIX API bindings for Dart:
1. [`package:posix`](https://pub.dev/packages/posix)
2. [`package:stdlibc`](https://pub.dev/packages/stdlibc)
 





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
