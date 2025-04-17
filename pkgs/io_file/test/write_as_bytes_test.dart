// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:io_file/io_file.dart';
import 'package:stdlibc/stdlibc.dart' as stdlibc;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'test_utils.dart';

void main() {
  //TODO(brianquinlan): test with a very long path.

  group('writeAsBytes', () {
    late String tmp;

    setUp(() => tmp = createTemp('writeAsBytes'));

    tearDown(() => deleteTemp(tmp));

    test('directory', () {
      expect(
        () => fileSystem.writeAsBytes(
          tmp,
          Uint8List(5),
          WriteMode.truncateExisting,
        ),
        throwsA(
          isA<FileSystemException>()
              .having((e) => e.message, 'message', 'open failed')
              .having(
                (e) => e.osError?.errorCode,
                'errorCode',
                Platform.isWindows ? win32.ERROR_ACCESS_DENIED : stdlibc.EISDIR,
              )
              .having((e) => e.path, 'path', tmp),
        ),
      );
    });

    test('symlink', () {
      final filePath = '$tmp/file1';
      final symlinkPath = '$tmp/file2';
      final data = randomUint8List(20);
      File(filePath).writeAsBytesSync(Uint8List(0));
      Link(symlinkPath).createSync(filePath);

      fileSystem.writeAsBytes(symlinkPath, data, WriteMode.truncateExisting);

      expect(fileSystem.readAsBytes(symlinkPath), data);
    });

    group('broken symlink', () {
      test('failExisting', () {
        final filePath = '$tmp/file1';
        final symlinkPath = '$tmp/file2';
        final data = randomUint8List(20);
        File(filePath).writeAsBytesSync(Uint8List(0));
        Link(symlinkPath).createSync(filePath);
        File(filePath).deleteSync();

        if (Platform.isWindows) {
          // Windows considers a broken symlink to not be an existing file.
          fileSystem.writeAsBytes(
            symlinkPath,
            Uint8List.fromList(data),
            WriteMode.failExisting,
          );

          // Should write at the symlink target, which should also mean that the
          // symlink is no longer broken.
          expect(fileSystem.readAsBytes(symlinkPath), data);
          expect(fileSystem.readAsBytes(filePath), data);
        } else {
          expect(
            () => fileSystem.writeAsBytes(
              symlinkPath,
              Uint8List.fromList(data),
              WriteMode.failExisting,
            ),
            throwsA(
              isA<PathExistsException>()
                  .having((e) => e.message, 'message', 'open failed')
                  .having(
                    (e) => e.osError?.errorCode,
                    'errorCode',
                    Platform.isWindows
                        ? win32.ERROR_FILE_EXISTS
                        : stdlibc.EEXIST,
                  )
                  .having((e) => e.path, 'path', symlinkPath),
            ),
          );
        }
      });
      test('truncateExisting', () {
        final filePath = '$tmp/file1';
        final symlinkPath = '$tmp/file2';
        final data = randomUint8List(20);
        File(filePath).writeAsBytesSync(Uint8List(0));
        Link(symlinkPath).createSync(filePath);
        File(filePath).deleteSync();

        fileSystem.writeAsBytes(symlinkPath, data, WriteMode.truncateExisting);

        // Should write at the symlink target, which should also mean that the
        // symlink is no longer broken.
        expect(fileSystem.readAsBytes(symlinkPath), data);
        expect(fileSystem.readAsBytes(filePath), data);
      });
    });

    group('new file', () {
      test('appendExisting', () {
        final data = randomUint8List(20);
        final path = '$tmp/file';

        fileSystem.writeAsBytes(
          path,
          Uint8List.fromList(data),
          WriteMode.appendExisting,
        );

        expect(File(path).readAsBytesSync(), data);
      });

      test('failExisting', () {
        final data = randomUint8List(20);
        final path = '$tmp/file';

        fileSystem.writeAsBytes(
          path,
          Uint8List.fromList(data),
          WriteMode.failExisting,
        );

        expect(File(path).readAsBytesSync(), data);
      });

      test('truncateExisting', () {
        final data = randomUint8List(20);
        final path = '$tmp/file';

        fileSystem.writeAsBytes(
          path,
          Uint8List.fromList(data),
          WriteMode.truncateExisting,
        );

        expect(File(path).readAsBytesSync(), data);
      });
    });

    group('existing file', () {
      test('appendExisting', () {
        final data = randomUint8List(20);
        final path = '$tmp/file';
        File(path).writeAsBytesSync([1, 2, 3]);

        fileSystem.writeAsBytes(
          path,
          Uint8List.fromList(data),
          WriteMode.appendExisting,
        );

        expect(File(path).readAsBytesSync(), [1, 2, 3] + data);
      });

      test('failExisting', () {
        final data = randomUint8List(20);
        final path = '$tmp/file';
        File(path).writeAsBytesSync([1, 2, 3]);

        expect(
          () => fileSystem.writeAsBytes(path, data, WriteMode.failExisting),
          throwsA(
            isA<PathExistsException>()
                .having((e) => e.message, 'message', 'open failed')
                .having(
                  (e) => e.osError?.errorCode,
                  'errorCode',
                  Platform.isWindows ? win32.ERROR_FILE_EXISTS : stdlibc.EEXIST,
                )
                .having((e) => e.path, 'path', path),
          ),
        );
      });

      test('truncateExisting', () {
        final data = randomUint8List(20);
        final path = '$tmp/file';
        File(path).writeAsBytesSync([1, 2, 3]);

        fileSystem.writeAsBytes(path, data, WriteMode.truncateExisting);

        expect(File(path).readAsBytesSync(), data);
      });
    });

    group('regular files', () {
      for (var i = 0; i <= 1024; ++i) {
        test('Write small file: $i bytes', () {
          final data = randomUint8List(i);
          final path = '$tmp/file';

          fileSystem.writeAsBytes(path, data);
          expect(fileSystem.readAsBytes(path), data);
        });
      }

      for (var i = 1 << 12; i <= 1 << 30; i <<= 4) {
        test('Write large file: $i bytes', () {
          final data = randomUint8List(i);
          final path = '$tmp/file';

          fileSystem.writeAsBytes(path, data);
          expect(fileSystem.readAsBytes(path), data);
        });
      }

      test('Write very large file', () {
        // FreeBSD/Windows cannot write more than INT_MAX at once.
        final data = randomUint8List(1 << 31 + 1);
        final path = '$tmp/file';

        fileSystem.writeAsBytes(path, data);
        expect(fileSystem.readAsBytes(path), data);
      }, skip: 'very slow');
    });
  });
}
