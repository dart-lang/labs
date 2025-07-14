// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:io_file/io_file.dart';
import 'package:io_file/posix_file_system.dart';
import 'package:io_file/src/internal_constants.dart' show blockSize;
import 'package:io_file/src/libc.dart' as libc;
import 'package:io_file/src/vm_windows_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'fifo.dart';
import 'test_utils.dart';

void main() {
  /// XXX check metadata

  group('copyFile', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('copyFile');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('copy does not preserve permissions', () {
      final data = randomUint8List(1024);
      final oldPath = '$tmp/file1';
      final newPath = '$tmp/file2';
      io.File(oldPath).writeAsBytesSync(data);

      // Give "other users" write permissions.
      using((arena) {
        // rw-rw-rw-
        if (libc.chmod(oldPath.toNativeUtf8(allocator: arena).cast(), 438) ==
            -1) {
          assert(false, 'libc.errno: ${libc.errno}');
        }
        final metadata = fileSystem.metadata(oldPath);
        assert((metadata as PosixMetadata).mode & libc.S_IWOTH != 0);
      });

      fileSystem.copyFile(oldPath, newPath);

      // Ensure that "other users" do not have write permissions on the copied
      // file.
      final metadata = fileSystem.metadata(newPath);
      expect((metadata as PosixMetadata).mode & libc.S_IWOTH, 0);
    }, skip: io.Platform.isWindows);

    test('copy does not preserve file attributes', () {
      final data = randomUint8List(1024);
      final oldPath = '$tmp/file1';
      final newPath = '$tmp/file2';
      io.File(oldPath).writeAsBytesSync(data);
      (fileSystem as WindowsFileSystem).setMetadata(oldPath, isReadOnly: true);

      fileSystem.copyFile(oldPath, newPath);

      final metadata = fileSystem.metadata(newPath);
      expect((metadata as WindowsMetadata).isReadOnly, isFalse);
    }, skip: !io.Platform.isWindows);

    test('copy file absolute path', () {
      final data = randomUint8List(1024);
      final oldPath = '$tmp/file1';
      final newPath = '$tmp/file2';
      io.File(oldPath).writeAsBytesSync(data);

      fileSystem.copyFile(oldPath, newPath);

      expect(io.File(newPath).readAsBytesSync(), data);
    });

    test('copy between absolute paths, long file names', () {
      final data = randomUint8List(1024);
      final oldPath = p.join(tmp, '1' * 255);
      final newPath = p.join(tmp, '2' * 255);
      io.File(oldPath).writeAsBytesSync(data);

      fileSystem.copyFile(oldPath, newPath);

      expect(io.File(newPath).readAsBytesSync(), data);
    });

    test('copy between relative path, long file names', () {
      final data = randomUint8List(1024);
      final oldPath = '1' * 255;
      final newPath = '2' * 255;
      io.File(oldPath).writeAsBytesSync(data);

      fileSystem.copyFile(oldPath, newPath);

      expect(io.File(newPath).readAsBytesSync(), data);
    });

    test('copy file to existing', () {
      final data = randomUint8List(1024);
      final oldPath = '$tmp/file1';
      final newPath = '$tmp/file2';
      io.File(oldPath).writeAsBytesSync(data);
      io.File(newPath).writeAsStringSync('Hello World!');

      fileSystem.copyFile(oldPath, newPath);

      expect(io.File(newPath).readAsBytesSync(), data);
    });

    test('copy to existant directory', () {
      final data = randomUint8List(1024);
      final oldPath = '$tmp/file1';
      final newPath = '$tmp/file2';
      io.File(oldPath).writeAsBytesSync(data);
      io.Directory(newPath).createSync();

      expect(
        () => fileSystem.copyFile(oldPath, newPath),
        throwsA(
          isA<IOFileException>().having(
            (e) => e.errorCode,
            'errorCode',
            io.Platform.isWindows
                ? 5 // ERROR_ACCESS_DENIED
                : 21, // EISDIR
          ),
        ),
      );
    });

    test('copy non-existent', () {
      final oldPath = '$tmp/file1';
      final newPath = '$tmp/file2';

      expect(
        () => fileSystem.copyFile(oldPath, newPath),
        throwsA(
          isA<PathNotFoundException>()
              .having((e) => e.path1, 'path1', oldPath)
              .having(
                (e) => e.errorCode,
                'errorCode',
                io.Platform.isWindows
                    ? win32.ERROR_FILE_NOT_FOUND
                    : errors.enoent,
              ),
        ),
      );
    });

    group('fifo', () {
      for (var i = 0; i <= 1024; ++i) {
        test('Read small file: $i bytes', () async {
          final data = randomUint8List(i);
          final oldPath = '$tmp/file1';
          final newPath = '$tmp/file2';
          final fifo =
              (await Fifo.create(oldPath))
                ..write(data)
                ..close();

          fileSystem.copyFile(fifo.path, newPath);

          expect(io.File(newPath).readAsBytesSync(), data);
        });
      }

      test('many single byte reads', () async {
        final data = randomUint8List(20);
        final oldPath = '$tmp/file1';
        final newPath = '$tmp/file2';
        final fifo = await Fifo.create(oldPath);
        for (var byte in data) {
          fifo
            ..write(Uint8List(1)..[0] = byte)
            ..delay(const Duration(milliseconds: 10));
        }
        fifo.close();

        fileSystem.copyFile(fifo.path, newPath);

        expect(io.File(newPath).readAsBytesSync(), data);
      });

      for (var i = blockSize - 2; i <= blockSize + 2; ++i) {
        test('Read close to `blockSize`: $i bytes', () async {
          final data = randomUint8List(i);
          final oldPath = '$tmp/file1';
          final newPath = '$tmp/file2';
          final fifo =
              (await Fifo.create(oldPath))
                ..write(data)
                ..close();

          fileSystem.copyFile(fifo.path, newPath);

          expect(io.File(newPath).readAsBytesSync(), data);
        });
      }
    });

    group('regular files', () {
      for (var i = 0; i <= 1024; ++i) {
        test('copyFile small file: $i bytes', () {
          final data = randomUint8List(i);
          final oldPath = '$tmp/file1';
          final newPath = '$tmp/file2';
          io.File(oldPath).writeAsBytesSync(data);

          fileSystem.copyFile(oldPath, newPath);

          expect(io.File(newPath).readAsBytesSync(), data);
        });
      }

      for (var i = blockSize - 2; i <= blockSize + 2; ++i) {
        test('copyFile close to `blockSize`: $i bytes', () {
          final data = randomUint8List(i);
          final oldPath = '$tmp/file1';
          final newPath = '$tmp/file2';
          io.File(oldPath).writeAsBytesSync(data);

          fileSystem.copyFile(oldPath, newPath);

          expect(io.File(newPath).readAsBytesSync(), data);
        });
      }
    });
  });
}
