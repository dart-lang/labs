// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io';

import 'package:io_file/io_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'fifo.dart';
import 'test_utils.dart';

void main() {
  group('metadata', () {
    late String tmp;
    late String cwd;

    setUp(() {
      tmp = createTemp('createTemporaryDirectory');
      cwd = fileSystem.currentDirectory;
      fileSystem.currentDirectory = tmp;
    });

    tearDown(() {
      fileSystem.currentDirectory = cwd;
      deleteTemp(tmp);
    });

    //TODO(brianquinlan): test with a very long path.

    test('path does not exist', () {
      expect(
        () => fileSystem.metadata('$tmp/file1'),
        throwsA(
          isA<PathNotFoundException>().having(
            (e) => e.osError?.errorCode,
            'errorCode',
            Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
          ),
        ),
      );
    });

    test('absolute path, long name', () {
      final path = p.join(tmp, 'f' * 255);
      File(path).writeAsStringSync('Hello World');

      final data = fileSystem.metadata(path);
      expect(data.isFile, isTrue);
    });

    test('relative path, long name', () {
      final path = 'f' * 255;
      File(path).writeAsStringSync('Hello World');

      final data = fileSystem.metadata(path);
      expect(data.isFile, isTrue);
    });

    group('file types', () {
      test('directory', () {
        final data = fileSystem.metadata(tmp);
        expect(data.isDirectory, isTrue);
        expect(data.isFile, isFalse);
        expect(data.isLink, isFalse);
        expect(data.type, FileSystemType.directory);
      });
      test(
        'tty',
        () {
          final data = fileSystem.metadata('/dev/tty');
          expect(data.isDirectory, isFalse);
          expect(data.isFile, isFalse);
          expect(data.isLink, isFalse);
          expect(data.type, FileSystemType.character);
        },
        skip:
            !(Platform.isAndroid |
                    Platform.isIOS |
                    Platform.isLinux |
                    Platform.isIOS)
                ? 'no /dev/tty'
                : false,
      );
      test('file', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = fileSystem.metadata(path);
        expect(data.isDirectory, isFalse);
        expect(data.isFile, isTrue);
        expect(data.isLink, isFalse);
        expect(data.type, FileSystemType.file);
      });
      test('fifo', () async {
        final fifo = (await Fifo.create('$tmp/file'))..close();

        final data = fileSystem.metadata(fifo.path);
        expect(data.isDirectory, isFalse);
        expect(data.isFile, isFalse);
        expect(data.isLink, isFalse);
        expect(
          data.type,
          Platform.isWindows ? FileSystemType.unknown : FileSystemType.pipe,
        );

        try {
          // On Windows, opening the pipe consumes it. See:
          // https://github.com/dotnet/runtime/issues/69604
          fileSystem.readAsBytes(fifo.path);
        } catch (_) {}
      });
      test('file link', () {
        File('$tmp/file1').writeAsStringSync('Hello World');
        final path = '$tmp/link';
        Link(path).createSync('$tmp/file1');

        final data = fileSystem.metadata(path);
        expect(data.isDirectory, isFalse);
        expect(data.isFile, isFalse);
        expect(data.isLink, isTrue);
        expect(data.type, FileSystemType.link);
      });
      test('directory link', () {
        Directory('$tmp/dir').createSync();
        final path = '$tmp/link';
        Link(path).createSync('$tmp/dir');

        final data = fileSystem.metadata(path);
        expect(data.isDirectory, isFalse);
        expect(data.isFile, isFalse);
        expect(data.isLink, isTrue);
        expect(data.type, FileSystemType.link);
      });
    });

    test(
      'isHidden',
      () {
        // Tested on iOS/macOS at: metadata_apple_test.dart
        // Tested on Windows at: metadata_windows_test.dart

        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World!');

        final data = fileSystem.metadata(path);
        expect(data.isHidden, isNull);
      },
      skip:
          (Platform.isIOS || Platform.isMacOS || Platform.isWindows)
              ? 'does not support hidden file metadata'
              : false,
    );
    group('size', () {
      test('empty file', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('');

        final data = fileSystem.metadata(path);
        expect(data.size, 0);
      });
      test('non-empty file', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World!');

        final data = fileSystem.metadata(path);
        expect(data.size, 12);
      });
    });

    group(
      'creation',
      () {
        test('newly created', () {
          final path = '$tmp/file1';
          File(path).writeAsStringSync('');

          final data = fileSystem.metadata(path);
          expect(
            data.creation!.millisecondsSinceEpoch,
            closeTo(DateTime.now().millisecondsSinceEpoch, 5000),
          );
        });
      },
      skip:
          !(Platform.isIOS || Platform.isMacOS || Platform.isWindows)
              ? 'creation not supported'
              : false,
    );

    group('modification', () {
      test('newly created', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World!');

        final data = fileSystem.metadata(path);
        expect(
          data.modification.millisecondsSinceEpoch,
          closeTo(DateTime.now().millisecondsSinceEpoch, 5000),
        );
      });
      test('modified after creation', () async {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World!');
        final data1 = fileSystem.metadata(path);

        await Future<void>.delayed(const Duration(milliseconds: 1000));
        File(path).writeAsStringSync('Hello World!');
        final data2 = fileSystem.metadata(path);

        expect(
          data2.modification.millisecondsSinceEpoch,
          greaterThan(data1.modification.millisecondsSinceEpoch),
        );
      });
    });
  });
}
