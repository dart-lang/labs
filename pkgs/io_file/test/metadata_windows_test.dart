// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('windows')
library;

import 'dart:io';

import 'package:io_file/src/vm_windows_file_system.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  final windowsFileSystem = WindowsFileSystem();

  group('windows metadata', () {
    late String tmp;

    setUp(() => tmp = createTemp('metadata'));

    tearDown(() => deleteTemp(tmp));

    group('isReadOnly', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isReadOnly, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isReadOnly: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isReadOnly, isTrue);
      });
    });

    group('isHidden', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isHidden, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isHidden: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isHidden, isTrue);
      });
    });

    group('isSystem', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isSystem, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isSystem: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isSystem, isTrue);
      });
    });

    group('needsArchive', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, needsArchive: false);

        final data = windowsFileSystem.metadata(path);
        expect(data.needsArchive, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, needsArchive: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.needsArchive, isTrue);
      });
    });

    group('isTemporary', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isTemporary, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isTemporary: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isTemporary, isTrue);
      });
    });

    group('isContentNotIndexed', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isContentIndexed: false);

        final data = windowsFileSystem.metadata(path);
        expect(data.isContentIndexed, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isContentIndexed: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isContentIndexed, isTrue);
      });
    });

    group('isOffline', () {
      test('false', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');

        final data = windowsFileSystem.metadata(path);
        expect(data.isOffline, isFalse);
      });
      test('true', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        windowsFileSystem.setMetadata(path, isOffline: true);

        final data = windowsFileSystem.metadata(path);
        expect(data.isOffline, isTrue);
      });
    });

    group('creation', () {
      test('new file', () {
        final path = '$tmp/file1';
        File(path).writeAsStringSync('Hello World');
        final maxCreationTime = DateTime.now().millisecondsSinceEpoch;

        final data = windowsFileSystem.metadata(path);
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

        final data = windowsFileSystem.metadata(path);
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

        final data = windowsFileSystem.metadata(path);
        expect(
          data.access.millisecondsSinceEpoch,
          inInclusiveRange(data.creation.millisecondsSinceEpoch, maxAccessTime),
        );
      });
    });
  });

  group('set metadata', () {
    late String tmp;

    setUp(() => tmp = createTemp('metadata'));

    tearDown(() => deleteTemp(tmp));

    for (var includeOriginalMetadata in [true, false]) {
      group('(use original metadata: $includeOriginalMetadata)', () {
        group('start with all file attributes set', () {
          late String path;
          late WindowsMetadata initialMetadata;

          setUp(() {
            path = '$tmp/file1';
            File(path).writeAsStringSync('Hello World');
            windowsFileSystem.setMetadata(
              path,
              isReadOnly: true,
              isHidden: true,
              isSystem: true,
              needsArchive: true,
              isTemporary: true,
              isContentIndexed: true,
              isOffline: true,
            );
            initialMetadata = windowsFileSystem.metadata(path);
          });

          test('set none', () {
            windowsFileSystem.setMetadata(
              path,
              original: includeOriginalMetadata ? initialMetadata : null,
            );
            expect(windowsFileSystem.metadata(path), initialMetadata);
          });
          test('unset isReadOnly', () {
            windowsFileSystem.setMetadata(
              path,
              isReadOnly: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });

          test('unset isHidden', () {
            windowsFileSystem.setMetadata(
              path,
              isHidden: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });
          test('unset isSystem', () {
            windowsFileSystem.setMetadata(
              path,
              isSystem: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });
          test('unset needsArchive', () {
            windowsFileSystem.setMetadata(
              path,
              needsArchive: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });
          test('unset isTemporary', () {
            windowsFileSystem.setMetadata(
              path,
              isTemporary: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isTrue);
          });
          test('unset isContentNotIndexed', () {
            windowsFileSystem.setMetadata(
              path,
              isContentIndexed: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isTrue);
          });
          test('unset isOffline', () {
            windowsFileSystem.setMetadata(
              path,
              isOffline: false,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
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
            windowsFileSystem.setMetadata(
              path,
              isReadOnly: false,
              isHidden: false,
              isSystem: false,
              needsArchive: false,
              isTemporary: false,
              isContentIndexed: false,
              isOffline: false,
            );
            initialMetadata = windowsFileSystem.metadata(path);
          });

          test('set none', () {
            windowsFileSystem.setMetadata(
              path,
              original: includeOriginalMetadata ? initialMetadata : null,
            );
            expect(windowsFileSystem.metadata(path), initialMetadata);
          });
          test('set isReadOnly', () {
            windowsFileSystem.setMetadata(
              path,
              isReadOnly: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isTrue);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });

          test('set isHidden', () {
            windowsFileSystem.setMetadata(
              path,
              isHidden: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isTrue);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });
          test('set isSystem', () {
            windowsFileSystem.setMetadata(
              path,
              isSystem: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isTrue);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });
          test('set needsArchive', () {
            windowsFileSystem.setMetadata(
              path,
              needsArchive: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isTrue);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });
          test('set isTemporary', () {
            windowsFileSystem.setMetadata(
              path,
              isTemporary: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isTrue);
            expect(data.isContentIndexed, isFalse);
            expect(data.isOffline, isFalse);
          });
          test('set isContentNotIndexed', () {
            windowsFileSystem.setMetadata(
              path,
              isContentIndexed: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
            expect(data.isReadOnly, isFalse);
            expect(data.isHidden, isFalse);
            expect(data.isSystem, isFalse);
            expect(data.needsArchive, isFalse);
            expect(data.isTemporary, isFalse);
            expect(data.isContentIndexed, isTrue);
            expect(data.isOffline, isFalse);
          });
          test('set isOffline', () {
            windowsFileSystem.setMetadata(
              path,
              isOffline: true,
              original: includeOriginalMetadata ? initialMetadata : null,
            );

            final data = windowsFileSystem.metadata(path);
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
