// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:io_file/io_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'test_utils.dart';

void main() {
  group('writeAsString', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('writeAsString');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    test('directory', () {
      expect(
        () => fileSystem.writeAsString(
          tmp,
          'Hello World!',
          WriteMode.truncateExisting,
        ),
        throwsA(
          isA<IOFileException>()
              .having(
                (e) => e.errorCode,
                'errorCode',
                io.Platform.isWindows
                    ? win32.ERROR_ACCESS_DENIED
                    : errors.eisdir,
              )
              .having((e) => e.path1, 'path1', tmp),
        ),
      );
    });

    test('symlink', () {
      final filePath = '$tmp/file1';
      final symlinkPath = '$tmp/file2';
      io.File(filePath).writeAsBytesSync(Uint8List(0));
      io.Link(symlinkPath).createSync(filePath);

      fileSystem.writeAsString(
        symlinkPath,
        'Hello World!',
        WriteMode.truncateExisting,
      );

      expect(io.File(symlinkPath).readAsStringSync(), 'Hello World!');
    });

    group('broken symlink', () {
      test('failExisting', () {
        final filePath = '$tmp/file1';
        final symlinkPath = '$tmp/file2';
        io.File(filePath).writeAsBytesSync(Uint8List(0));
        io.Link(symlinkPath).createSync(filePath);
        io.File(filePath).deleteSync();

        if (io.Platform.isWindows) {
          // Windows considers a broken symlink to not be an existing file.
          fileSystem.writeAsString(
            symlinkPath,
            'Hello World!',
            WriteMode.failExisting,
          );

          // Should write at the symlink target, which should also mean that the
          // symlink is no longer broken.
          expect(io.File(symlinkPath).readAsStringSync(), 'Hello World!');
          expect(io.File(filePath).readAsStringSync(), 'Hello World!');
        } else {
          expect(
            () => fileSystem.writeAsString(
              symlinkPath,
              'Hello World!',
              WriteMode.failExisting,
            ),
            throwsA(
              isA<PathExistsException>()
                  .having(
                    (e) => e.errorCode,
                    'errorCode',
                    io.Platform.isWindows
                        ? win32.ERROR_FILE_EXISTS
                        : errors.eexist,
                  )
                  .having((e) => e.path1, 'path1', symlinkPath),
            ),
          );
        }
      });
      test('truncateExisting', () {
        final filePath = '$tmp/file1';
        final symlinkPath = '$tmp/file2';
        io.File(filePath).writeAsBytesSync(Uint8List(0));
        io.Link(symlinkPath).createSync(filePath);
        io.File(filePath).deleteSync();

        fileSystem.writeAsString(
          symlinkPath,
          'Hello World!',
          WriteMode.truncateExisting,
        );

        // Should write at the symlink target, which should also mean that the
        // symlink is no longer broken.
        expect(io.File(symlinkPath).readAsStringSync(), 'Hello World!');
        expect(io.File(filePath).readAsStringSync(), 'Hello World!');
      });
    });

    group('new file', () {
      test('appendExisting', () {
        final path = '$tmp/file';

        fileSystem.writeAsString(path, 'Hello World', WriteMode.appendExisting);

        expect(io.File(path).readAsStringSync(), 'Hello World');
      });

      test('failExisting', () {
        final path = '$tmp/file';

        fileSystem.writeAsString(path, 'Hello World', WriteMode.failExisting);

        expect(io.File(path).readAsStringSync(), 'Hello World');
      });

      test('truncateExisting', () {
        final path = '$tmp/file';

        fileSystem.writeAsString(
          path,
          'Hello World',
          WriteMode.truncateExisting,
        );

        expect(io.File(path).readAsStringSync(), 'Hello World');
      });
    });

    group('existing file', () {
      test('appendExisting', () {
        final path = '$tmp/file';
        io.File(path).writeAsStringSync('message: ');

        fileSystem.writeAsString(
          path,
          'Hello World!',
          WriteMode.appendExisting,
        );

        expect(io.File(path).readAsStringSync(), 'message: Hello World!');
      });

      test('failExisting', () {
        final path = '$tmp/file';
        io.File(path).writeAsBytesSync([1, 2, 3]);

        expect(
          () => fileSystem.writeAsString(
            path,
            'Hello World!',
            WriteMode.failExisting,
          ),
          throwsA(
            isA<PathExistsException>()
                .having(
                  (e) => e.errorCode,
                  'errorCode',
                  io.Platform.isWindows
                      ? win32.ERROR_FILE_EXISTS
                      : errors.eexist,
                )
                .having((e) => e.path1, 'path1', path),
          ),
        );
      });

      test('truncateExisting', () {
        final path = '$tmp/file';
        io.File(path).writeAsBytesSync([1, 2, 3]);

        fileSystem.writeAsString(
          path,
          'Hello World!',
          WriteMode.truncateExisting,
        );

        expect(io.File(path).readAsStringSync(), 'Hello World!');
      });
    });

    test('absolute path, long file name', () {
      final path = p.join(tmp, 'f' * 255);

      fileSystem.writeAsString(path, 'Hello World!');
      expect(io.File(path).readAsStringSync(), 'Hello World!');
    });

    test('relative path, long file name', () {
      final path = 'f' * 255;

      fileSystem.writeAsString(path, 'Hello World!');
      expect(io.File(path).readAsStringSync(), 'Hello World!');
    });

    group('encoding', () {
      test('non-ascii', () {
        final path = '$tmp/file';

        fileSystem.writeAsString(
          path,
          'Γειά σου!',
          WriteMode.failExisting,
          utf8,
        );
        expect(io.File(path).readAsStringSync(), 'Γειά σου!');
      });

      test('unencodable', () {
        final path = '$tmp/file';

        expect(
          () => fileSystem.writeAsString(
            path,
            'Γειά σου!',
            WriteMode.failExisting,
            ascii,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('lineTerminator', () {
      test('illegal', () {
        final path = '$tmp/file';

        expect(
          () => fileSystem.writeAsString(
            path,
            'Greeting:\nHello World!',
            WriteMode.failExisting,
            utf8,
            '-',
          ),
          throwsArgumentError,
        );
      });

      test('null', () {
        final path = '$tmp/file';

        fileSystem.writeAsString(
          path,
          'Greeting:\nHello World!\rHi!\r\n',
          WriteMode.failExisting,
          utf8,
          null,
        );

        expect(
          io.File(path).readAsStringSync(),
          io.Platform.isWindows
              ? 'Greeting:\r\nHello World!\rHi!\r\r\n'
              : 'Greeting:\nHello World!\rHi!\r\n',
        );
      });

      test(r'\n', () {
        final path = '$tmp/file';

        fileSystem.writeAsString(
          path,
          'Greeting:\nHello World!\rHi!\r\n',
          WriteMode.failExisting,
          utf8,
          '\n',
        );

        expect(
          io.File(path).readAsStringSync(),
          'Greeting:\nHello World!\rHi!\r\n',
        );
      });

      test(r'\r\n', () {
        final path = '$tmp/file';

        fileSystem.writeAsString(
          path,
          'Greeting:\nHello World!\rHi!\r\n',
          WriteMode.failExisting,
          utf8,
          '\r\n',
        );

        expect(
          io.File(path).readAsStringSync(),
          'Greeting:\r\nHello World!\rHi!\r\r\n',
        );
      });
    });
  });
}
