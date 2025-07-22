// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:io_file/io_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:win32/win32.dart' as win32;

import 'errors.dart' as errors;
import 'fifo.dart';
import 'file_system_file_utils.dart' hide fileUtils;
import 'test_utils.dart';

void tests(FileUtils utils, FileSystem fs) {
  late String tmp;
  late String cwd;

  setUp(() {
    tmp = utils.createTestDirectory('createDirectory');
    cwd = fs.currentDirectory;
    fs.currentDirectory = tmp;
  });

  tearDown(() {
    fs.currentDirectory = cwd;
    utils.deleteDirectoryTree(tmp);
  });
  test('path does not exist', () {
    expect(
      () => fs.metadata('$tmp/file1'),
      throwsA(
        isA<PathNotFoundException>().having(
          (e) => e.errorCode,
          'errorCode',
          io.Platform.isWindows ? win32.ERROR_FILE_NOT_FOUND : errors.enoent,
        ),
      ),
    );
  });

  test('absolute path, long name', () {
    final path = p.join(tmp, 'f' * 255);
    utils.createTextFile(path, 'Hello World');

    final data = fs.metadata(path);
    expect(data.isFile, isTrue);
  });

  test('relative path, long name', () {
    final path = 'f' * 255;
    utils.createTextFile(path, 'Hello World');

    final data = fs.metadata(path);
    expect(data.isFile, isTrue);
  });

  group('file types', () {
    test('directory', () {
      final data = fs.metadata(tmp);
      expect(data.isDirectory, isTrue);
      expect(data.isFile, isFalse);
      expect(data.isLink, isFalse);
      expect(data.type, FileSystemType.directory);
    });
    test(
      'tty',
      () {
        final data = fs.metadata('/dev/tty');
        expect(data.isDirectory, isFalse);
        expect(data.isFile, isFalse);
        expect(data.isLink, isFalse);
        expect(data.type, FileSystemType.character);
      },
      skip:
          !(io.Platform.isAndroid |
                  io.Platform.isIOS |
                  io.Platform.isLinux |
                  io.Platform.isIOS)
              ? 'no /dev/tty'
              : false,
    );
    test('file', () {
      final path = '$tmp/file1';
      utils.createTextFile(path, 'Hello World');

      final data = fs.metadata(path);
      expect(data.isDirectory, isFalse);
      expect(data.isFile, isTrue);
      expect(data.isLink, isFalse);
      expect(data.type, FileSystemType.file);
    });
    test('fifo', () async {
      final fifo = (await Fifo.create('$tmp/file'))..close();

      final data = fs.metadata(fifo.path);
      expect(data.isDirectory, isFalse);
      expect(data.isFile, isFalse);
      expect(data.isLink, isFalse);
      expect(
        data.type,
        io.Platform.isWindows ? FileSystemType.unknown : FileSystemType.pipe,
      );

      try {
        // On Windows, opening the pipe consumes it. See:
        // https://github.com/dotnet/runtime/issues/69604
        fs.readAsBytes(fifo.path);
      } catch (_) {}
    });
    test('file link', () {
      utils.createTextFile('$tmp/file1', 'Hello World');
      final path = '$tmp/link';
      io.Link(path).createSync('$tmp/file1');

      final data = fs.metadata(path);
      expect(data.isDirectory, isFalse);
      expect(data.isFile, isFalse);
      expect(data.isLink, isTrue);
      expect(data.type, FileSystemType.link);
    });
    test('directory link', () {
      io.Directory('$tmp/dir').createSync();
      final path = '$tmp/link';
      io.Link(path).createSync('$tmp/dir');

      final data = fs.metadata(path);
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
      io.File(path).writeAsStringSync('Hello World!');

      final data = fs.metadata(path);
      expect(data.isHidden, isNull);
    },
    skip:
        (io.Platform.isIOS || io.Platform.isMacOS || io.Platform.isWindows)
            ? 'does not support hidden file metadata'
            : false,
  );
  group('size', () {
    test('empty file', () {
      final path = '$tmp/file1';
      io.File(path).writeAsStringSync('');

      final data = fs.metadata(path);
      expect(data.size, 0);
    });
    test('non-empty file', () {
      final path = '$tmp/file1';
      io.File(path).writeAsStringSync('Hello World!');

      final data = fs.metadata(path);
      expect(data.size, 12);
    });
  });

  group(
    'creation',
    () {
      test('newly created', () {
        final path = '$tmp/file1';
        io.File(path).writeAsStringSync('');

        final data = fs.metadata(path);
        expect(
          data.creation!.millisecondsSinceEpoch,
          closeTo(DateTime.now().millisecondsSinceEpoch, 5000),
        );
      });
    },
    skip:
        !(io.Platform.isIOS || io.Platform.isMacOS || io.Platform.isWindows)
            ? 'creation not supported'
            : false,
  );

  group('modification', () {
    test('newly created', () {
      final path = '$tmp/file1';
      io.File(path).writeAsStringSync('Hello World!');

      final data = fs.metadata(path);
      expect(
        data.modification.millisecondsSinceEpoch,
        closeTo(DateTime.now().millisecondsSinceEpoch, 5000),
      );
    });
    test('modified after creation', () async {
      final path = '$tmp/file1';
      io.File(path).writeAsStringSync('Hello World!');
      final data1 = fs.metadata(path);

      await Future<void>.delayed(const Duration(milliseconds: 1000));
      io.File(path).writeAsStringSync('Hello World!');
      final data2 = fs.metadata(path);

      expect(
        data2.modification.millisecondsSinceEpoch,
        greaterThan(data1.modification.millisecondsSinceEpoch),
      );
    });
  });
}

void main() {
  group('metadata', () {
    group('dart:io verification', () => tests(fileUtils(), fileSystem));
    group(
      'self verification',
      () => tests(FileSystemFileUtils(fileSystem), fileSystem),
    );
  });
}
