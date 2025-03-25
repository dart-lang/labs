// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('posix')
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:io_file/io_file.dart';
import 'package:io_file/posix_file_system.dart' show blockSize, maxReadSize;
import 'package:stdlibc/stdlibc.dart' as stdlibc;
import 'package:test/test.dart';

import 'test_utils.dart';

// Writes data to a FIFO in a seperate isolate.
class FifoWriter {
  final SendPort _sendChannel;

  FifoWriter._(this._sendChannel);

  static Future<FifoWriter> create(String path) async {
    final p = ReceivePort();
    await Isolate.spawn<SendPort>((port) {
      final receivePort = ReceivePort();
      port.send(receivePort.sendPort);

      final fd = stdlibc.open(
        path,
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
    return FifoWriter._((await p.first) as SendPort);
  }

  void write(Uint8List data) {
    _sendChannel.send(data);
  }

  void delay(Duration d) {
    _sendChannel.send(d);
  }

  void close() {
    _sendChannel.send(null);
  }
}

void main() {
  //TODO(brianquinlan): test with a very long path.

  group('readAsBytes', () {
    late String tmp;

    setUp(() => tmp = createTemp('readAsBytes'));

    tearDown(() => deleteTemp(tmp));

    test('non-existant file', () {
      expect(
        () => fileSystem.readAsBytes('doesnotexist'),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.message, 'message', 'open failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                2, // ENOENT
              )
              .having((e) => e.path, 'path', 'doesnotexist'),
        ),
      );
    });

    test('directory', () {
      expect(
        () => fileSystem.readAsBytes(tmp),
        throwsA(
          isA<FileSystemException>()
              .having((e) => e.message, 'message', 'read failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                21, // EISDIR
              )
              .having((e) => e.path, 'path', tmp),
        ),
      );
    });

    test('symlink', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      final data = randomUint8List(20);
      File(path1).writeAsBytesSync(data);
      Link(path2).createSync(path1);

      expect(fileSystem.readAsBytes(path2), data);
    });

    test('broken symlink', () {
      final path1 = '$tmp/file1';
      final path2 = '$tmp/file2';

      final data = randomUint8List(20);
      File(path1).writeAsBytesSync(data);
      Link(path2).createSync(path1);
      File(path1).deleteSync();

      expect(
        () => fileSystem.readAsBytes(path2),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.message, 'message', 'open failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                2, // ENOENT
              )
              .having((e) => e.path, 'path', path2),
        ),
      );
    });

    group('fifo (does not have length)', () {
      for (var i = 0; i <= 1024; ++i) {
        test('Read small file: $i bytes', () async {
          final data = randomUint8List(i);
          final path = '$tmp/file';
          stdlibc.mkfifo(path, 438); // 0666

          (await FifoWriter.create(path))
            ..write(data)
            ..close();

          expect(fileSystem.readAsBytes(path), data);
        });
      }

      test('many single byte reads', () async {
        final path = '$tmp/file';
        stdlibc.mkfifo(path, 438); // 0666

        final writer = await FifoWriter.create(path);
        final data = randomUint8List(20);

        for (var byte in data) {
          writer
            ..write(Uint8List(1)..[0] = byte)
            ..delay(const Duration(milliseconds: 10));
        }
        writer.close();
        expect(fileSystem.readAsBytes(path), data);
      });

      for (var i = blockSize - 2; i <= blockSize + 2; ++i) {
        test('Read close to `blockSize`: $i bytes', () async {
          final data = randomUint8List(i);
          final path = '$tmp/file1';
          stdlibc.mkfifo(path, 438); // 0666

          (await FifoWriter.create(path))
            ..write(data)
            ..close();
          expect(fileSystem.readAsBytes(path), data);
        });
      }
    });

    group('regular files', () {
      for (var i = 0; i <= 1024; ++i) {
        test('Read small file: $i bytes', () {
          final data = randomUint8List(i);
          final path1 = '$tmp/file1';

          File(path1).writeAsBytesSync(data);
          expect(fileSystem.readAsBytes(path1), data);
        });
      }

      for (var i = maxReadSize - 2; i <= maxReadSize + 2; ++i) {
        test('Read close to `maxReadSize`: $i bytes', () {
          final data = randomUint8List(i);
          final path1 = '$tmp/file1';

          File(path1).writeAsBytesSync(data);
          expect(fileSystem.readAsBytes(path1), data);
        });
      }

      test('very large file', () {
        final data = randomUint8List(1 << 31 + 1);
        final path = '$tmp/file';

        File(path).writeAsBytesSync(data);
        expect(fileSystem.readAsBytes(path), data);
      }, skip: 'very slow');
    });
  });
}
