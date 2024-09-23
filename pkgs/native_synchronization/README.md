[![Dart](https://github.com/dart-lang/native_synchronization/actions/workflows/dart.yaml/badge.svg)](https://github.com/dart-lang/native_synchronization/actions/workflows/dart.yaml)
[![pub package](https://img.shields.io/pub/v/native_synchronization.svg)](https://pub.dev/packages/native_synchronization)
[![package publisher](https://img.shields.io/pub/publisher/native_synchronization.svg)](https://pub.dev/packages/native_synchronization/publisher)

This package exposes a portable interface for low-level thread
synchronization primitives like `Mutex` and `ConditionVariable`.

It also provides some slightly more high-level synchronization primitives
like `Mailbox` built on top of low-level primitives.

## Status: experimental

**NOTE**: This package is currently experimental and published under the
[labs.dart.dev](https://dart.dev/dart-team-packages) pub publisher in order to
solicit feedback.

For packages in the labs.dart.dev publisher we generally plan to either graduate
the package into a supported publisher (dart.dev, tools.dart.dev) after a period
of feedback and iteration, or discontinue the package. These packages have a
much higher expected rate of API and breaking changes.

Your feedback is valuable and will help us evolve this package. For general
feedback, suggestions, and comments, please file an issue in the
[bug tracker](https://github.com/dart-lang/native_synchronization/issues).
