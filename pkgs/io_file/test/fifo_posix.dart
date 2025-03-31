// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:stdlibc/stdlibc.dart' as stdlibc;

import 'fifo.dart';

/// Implements a [Fifo] using POSIX fifos.
class FifoPosix implements Fifo {
  final SendPort _sendChannel;

  @override
  final String path;

  FifoPosix._(this.path, this._sendChannel);

  static Future<FifoPosix> create(String suggestedPath) async {
    final p = ReceivePort();

    stdlibc.mkfifo(suggestedPath, 438); // 0436 => permissions: -rw-rw-rw-

    await Isolate.spawn<SendPort>((port) {
      final receivePort = ReceivePort();
      port.send(receivePort.sendPort);

      final fd = stdlibc.open(
        suggestedPath,
        flags: stdlibc.O_WRONLY | stdlibc.O_CLOEXEC,
      );

      if (fd == -1) {
        throw AssertionError('could not open fifo: ${stdlibc.errno}');
      }
      late final StreamSubscription<dynamic> subscription;
      Future<void> pause(Duration d) async {
        subscription.pause();
        await Future<void>.delayed(d);
        subscription.resume();
      }

      subscription = receivePort.listen(
        (message) => switch (message) {
          Uint8List data => stdlibc.write(fd, data),

          Duration d => pause(d),
          null => stdlibc.close(fd),

          final other => throw UnsupportedError('unexpected message: $other'),
        },
      );
    }, p.sendPort);
    return FifoPosix._(suggestedPath, (await p.first) as SendPort);
  }

  @override
  void write(Uint8List data) {
    _sendChannel.send(data);
  }

  @override
  void delay(Duration d) {
    _sendChannel.send(d);
  }

  @override
  void close() {
    _sendChannel.send(null);
  }
}
