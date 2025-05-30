// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:uuid/uuid.dart';
import 'package:win32/win32.dart' as win32;

import 'fifo.dart';

/// Implements a [Fifo] using Windows named pipes.
class FifoWindows implements Fifo {
  final SendPort _sendChannel;

  @override
  final String path;

  FifoWindows._(this.path, this._sendChannel);

  static Future<FifoWindows> create(String suggestedPath) => ffi.using((
    arena,
  ) async {
    final path = r'\\.\pipe\test' + const Uuid().v4();
    win32.GetLastError();
    final f = win32.CreateNamedPipe(
      path.toNativeUtf16(allocator: arena),
      win32.PIPE_ACCESS_OUTBOUND | win32.FILE_FLAG_FIRST_PIPE_INSTANCE,
      win32.PIPE_TYPE_BYTE |
          win32.PIPE_READMODE_BYTE |
          win32.PIPE_WAIT |
          win32.PIPE_REJECT_REMOTE_CLIENTS,
      win32.PIPE_UNLIMITED_INSTANCES,
      512, // outBufferSize in bytes,
      512, // inBufferSize in bytes
      0, // timeout in milliseconds
      nullptr,
    );
    if (f == win32.INVALID_HANDLE_VALUE) {
      throw AssertionError('could not create pipe: ${win32.GetLastError()}');
    }
    final p = ReceivePort();
    await Isolate.spawn<SendPort>((port) {
      // Calling `GetLastError` for the first time causes the `GetLastError`
      // symbol to be loaded, which resets `GetLastError`. So make a harmless
      // call before the value is needed.
      win32.GetLastError();

      final receivePort = ReceivePort();
      port.send(receivePort.sendPort);
      if (win32.ConnectNamedPipe(f, nullptr) == win32.FALSE) {
        final error = win32.GetLastError();
        if (error !=
            // The client connected in the time between the pipe's creation and
            // the call to `ConnectNamedPipe`.
            win32.ERROR_PIPE_CONNECTED) {
          throw AssertionError('error waiting for client connection: $error');
        }
      }

      late final StreamSubscription<dynamic> subscription;

      Future<void> pause(Duration d) async {
        subscription.pause();
        await Future<void>.delayed(d);
        subscription.resume();
      }

      void write(Uint8List data) {
        final buffer = arena.allocate<Uint8>(data.length);
        buffer.asTypedList(data.length).setAll(0, data);
        final bytesWritten = arena<win32.DWORD>();
        if (win32.WriteFile(f, buffer, data.length, bytesWritten, nullptr) ==
            win32.FALSE) {
          final error = win32.GetLastError();
          throw AssertionError('could not write to pipe: $error');
        }
        assert(bytesWritten.value == data.length);
      }

      subscription = receivePort.listen(
        (message) => switch (message) {
          Uint8List data => write(data),
          Duration d => pause(d),
          null => win32.CloseHandle(f),

          final other => throw UnsupportedError('unexpected message: $other'),
        },
      );
    }, p.sendPort);
    return FifoWindows._(path, (await p.first) as SendPort);
  });

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
