// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('windows')
library;

import 'dart:io';

import 'package:io_file/src/vm_windows_file_system.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'file_system_file_utils.dart' hide fileUtils;
import 'test_utils.dart';

void tests(FileUtils utils, WindowsFileSystem fileSystem) {
  late String tmp;
  late String cwd;

  setUp(() {
    tmp = utils.createTestDirectory('createDirectory');
    cwd = fileSystem.currentDirectory;
    fileSystem.currentDirectory = tmp;
  });

  tearDown(() {
    fileSystem.currentDirectory = cwd;
    utils.deleteDirectoryTree(tmp);
  });

  group('isReadOnly', () {
    test('false', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');

      final data = fileSystem.metadata(path);
      expect(data.isReadOnly, isFalse);
    });
    test('true', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      fileSystem.setMetadata(path, isReadOnly: true);

      final data = fileSystem.metadata(path);
      expect(data.isReadOnly, isTrue);
    });
  });

  group('isHidden', () {
    test('false', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');

      final data = fileSystem.metadata(path);
      expect(data.isHidden, isFalse);
    });
    test('true', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      fileSystem.setMetadata(path, isHidden: true);

      final data = fileSystem.metadata(path);
      expect(data.isHidden, isTrue);
    });
  });

  group('isSystem', () {
    test('false', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');

      final data = fileSystem.metadata(path);
      expect(data.isSystem, isFalse);
    });
    test('true', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      fileSystem.setMetadata(path, isSystem: true);

      final data = fileSystem.metadata(path);
      expect(data.isSystem, isTrue);
    });
  });

  group('needsArchive', () {
    test('false', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      fileSystem.setMetadata(path, needsArchive: false);

      final data = fileSystem.metadata(path);
      expect(data.needsArchive, isFalse);
    });
    test('true', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      fileSystem.setMetadata(path, needsArchive: true);

      final data = fileSystem.metadata(path);
      expect(data.needsArchive, isTrue);
    });
  });

  group('isTemporary', () {
    test('false', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');

      final data = fileSystem.metadata(path);
      expect(data.isTemporary, isFalse);
    });
    test('true', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      fileSystem.setMetadata(path, isTemporary: true);

      final data = fileSystem.metadata(path);
      expect(data.isTemporary, isTrue);
    });
  });

  group('isContentNotIndexed', () {
    test('false', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      fileSystem.setMetadata(path, isContentIndexed: false);

      final data = fileSystem.metadata(path);
      expect(data.isContentIndexed, isFalse);
    });
    test('true', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      fileSystem.setMetadata(path, isContentIndexed: true);

      final data = fileSystem.metadata(path);
      expect(data.isContentIndexed, isTrue);
    });
  });

  group('isOffline', () {
    test('false', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');

      final data = fileSystem.metadata(path);
      expect(data.isOffline, isFalse);
    });
    test('true', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      fileSystem.setMetadata(path, isOffline: true);

      final data = fileSystem.metadata(path);
      expect(data.isOffline, isTrue);
    });
  });

  group('creation', () {
    test('new file', () {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      final maxCreationTime = DateTime.now().millisecondsSinceEpoch;

      final data = fileSystem.metadata(path);
      expect(
        data.creation.millisecondsSinceEpoch,
        // Creation time within 1 second.
        inInclusiveRange(maxCreationTime - 1000, maxCreationTime),
      );
    });
  });

  group('modificiation', () {
    test('new file', () async {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      await Future<void>.delayed(const Duration(seconds: 1));
      File(path).writeAsStringSync('How are you?');
      final maxModificationTime = DateTime.now().millisecondsSinceEpoch;

      final data = fileSystem.metadata(path);
      expect(
        data.modification.millisecondsSinceEpoch,
        inInclusiveRange(
          data.creation.millisecondsSinceEpoch + 1000,
          maxModificationTime,
        ),
      );
    });
  });

  group('access', () {
    test('new file', () async {
      final path = '$tmp/file1';
      File(path).writeAsStringSync('Hello World');
      File(path).readAsBytesSync();
      final maxAccessTime = DateTime.now().millisecondsSinceEpoch;

      final data = fileSystem.metadata(path);
      expect(
        data.access.millisecondsSinceEpoch,
        inInclusiveRange(data.creation.millisecondsSinceEpoch, maxAccessTime),
      );
    });
  });

  group('set metadata', () {
    test('absolute path, long name', () {
      final path = p.join(tmp, 'f' * 255);
      File(path).writeAsStringSync('Hello World');

      fileSystem.setMetadata(path, isReadOnly: true);

      expect(fileSystem.metadata(path).isReadOnly, isTrue);
    });

    test('relative path, long name', () {
      final path = 'f' * 255;
      File(path).writeAsStringSync('Hello World');

      fileSystem.setMetadata(path, isReadOnly: true);

      expect(fileSystem.metadata(path).isReadOnly, isTrue);
    });

    for (var includeOriginalMetadata in [true, false]) {
      group('(use original metadata: $includeOriginalMetadata)', () {
        group('start with all file attributes set', () {
          late String path;
          late WindowsMetadata initialMetadata;

          setUp(() {
            path = '$tmp/file1';
            File(path).writeAsStringSync('Hello World');
            fileSystem.setMetadata(
              path,
              isReadOnly: true,
              isHidden: true,
              isSystem: true,
              needsArchive: true,
              isTemporary: true,
              isContentIndexed: true,
              isOffline: true,
            );
            initialMetadata = fileSystem.metadata(path);
          });

          test('set none', () {
            fileSystem.setMetadata(
              path,
              original: includeOriginalMetadata ? initialMetadata : null,
            );
            expect(fileSystem.metadata(path), initialMetadata);
          });
          test('unset isReadOnly', () {
            fileSystem.setMetadata(
              path,
              isReadOnly: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });

          test('unset isHidden', () {
            fileSystem.setMetadata(
              path,
              isHidden: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });
          test('unset isSystem', () {
            fileSystem.setMetadata(
              path,
              isSystem: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });
          test('unset needsArchive', () {
            fileSystem.setMetadata(
              path,
              needsArchive: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });
          test('unset isTemporary', () {
            fileSystem.setMetadata(
              path,
              isTemporary: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });
          test('unset isContentNotIndexed', () {
            fileSystem.setMetadata(
              path,
              isContentIndexed: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isTrue);
          });
          test('unset isOffline', () {
            fileSystem.setMetadata(
              path,
              isOffline: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isFalse);
          });
        });

        group('start with no file attributes set', () {
          late String path;
          late WindowsMetadata initialMetadata;

          setUp(() {
            path = '$tmp/file1';
            File(path).writeAsStringSync('Hello World');
            fileSystem.setMetadata(
              path,
              isReadOnly: false,
              isHidden: false,
              isSystem: false,
              needsArchive: false,
              isTemporary: false,
              isContentIndexed: false,
              isOffline: false,
            );
            initialMetadata = fileSystem.metadata(path);
          });

          test('set none', () {
            fileSystem.setMetadata(
              path,
              original: includeOriginalMetadata ? initialMetadata : null,
            );
            expect(fileSystem.metadata(path), initialMetadata);
          });
          test('set isReadOnly', () {
            fileSystem.setMetadata(
              path,
              isReadOnly: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });

          test('set isHidden', () {
            fileSystem.setMetadata(
              path,
              isHidden: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });
          test('set isSystem', () {
            fileSystem.setMetadata(
              path,
              isSystem: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });
          test('set needsArchive', () {
            fileSystem.setMetadata(
              path,
              needsArchive: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });
          test('set isTemporary', () {
            fileSystem.setMetadata(
              path,
              isTemporary: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });
          test('set isContentNotIndexed', () {
            fileSystem.setMetadata(
              path,
              isContentIndexed: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isFalse);
          });
          test('set isOffline', () {
            fileSystem.setMetadata(
              path,
              isOffline: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = fileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isTrue);
          });
        });
      });
    }
  });
}

void main() {
  group('windows metadata', () {
    final fileSystem = WindowsFileSystem();
    group('dart:io verification', () => tests(fileUtils(), fileSystem));
    group(
      'self verification',
      () => tests(FileSystemFileUtils(fileSystem), fileSystem),
    );
  });
}
