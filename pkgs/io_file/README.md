This package is an **experimental** reimplementation of the `dart:io` file
system API using FFI.

See
[package:io_file - a pure dart file system API](https://docs.google.com/document/d/17dPegdklLKQz4fjrRDHaN0ld7FlmK0prncZQUTx68nk/edit?usp=sharing)

## Progress

### FileSystem

| Feature               | Android | Linux | iOS   | macOS | Windows |
| :---                  |  :---:  | :---: | :---: | :---: | :----:  |    
|  canonicalize path    |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  copy file            |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  create directory     |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  create hard link     |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  create symbolic link |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  create tmp directory |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  create tmp file      |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  delete directory     |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  delete file          |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  delete tree          |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  enum dir contents    |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  exists               |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  get metadata (stat)  |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  open                 |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  read file (bytes)    |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  read file (lines)    |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  read file (string)   |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  rename               |   [ ]   |  [X]  |  [ ]  |  [X]  |   [X]   |
|  set permissions      |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  write file (bytes)   |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  write file (string)  |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |

### File

| Feature               | Android | Linux | iOS   | macOS | Windows |
| :---                  |  :---:  | :---: | :---: | :---: | :----:  |    
|  get file descriptor  |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  get file length      |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  get file metadata    |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  get file position    |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  read                 |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |
|  write                |   [ ]   |  [ ]  |  [ ]  |  [ ]  |   [ ]   |

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
