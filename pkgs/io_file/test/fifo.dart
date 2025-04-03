// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'fifo_posix.dart';
import 'fifo_windows.dart';

/// An abstraction for a write-only object with a path.
///
/// Used to test reading from a file that does not report a reliable length.
abstract class Fifo {
  static Future<Fifo> create(String suggestedPath) {
    if (Platform.isWindows) {
      return FifoWindows.create(suggestedPath);
    } else {
      return FifoPosix.create(suggestedPath);
    }
  }

  /// The file system path of the Fifo used to read it.
  String get path;

  /// Writes data to the [Fifo]. Does not block.
  void write(Uint8List data);

  /// Inserts a delay between the next [write] or [close]. Does not block.
  void delay(Duration d);

  /// Closes the [Fifo]. Does not block.
  void close();
}
