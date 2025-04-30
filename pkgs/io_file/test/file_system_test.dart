// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;
import 'dart:typed_data'; // Import needed for Uint8List if used elsewhere

import 'package:io_file/io_file.dart';
// ignore: implementation_imports
import 'package:io_file/src/vm_posix_file_system.dart';
import 'package:io_file/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('FileSystem', () {
    // Test that the base FileSystem.rename throws UnsupportedError
    test('rename abstract method throws', () {
      expect(() => FileSystem().rename('a', 'b'), throwsUnsupportedError);
    });
    // Note: We don't test the other abstract methods for throwing
    // UnsupportedError here, as that's their defined behavior.
    // We only test specific implementations below.
  });

  // --- PosixFileSystem Tests ---
  if (Platform.isLinux || Platform.isMacOS) {
    group('PosixFileSystem', () {
      late PosixFileSystem fs;

      setUp(() {
        fs = PosixFileSystem();
      });

      group('createTemporaryDirectory', () {
        test('successfully creates a temporary directory', () {
          const templatePrefix = '/tmp/io_file_test.';
          const template = '$templatePrefixXXXXXX';
          final resultPath = fs.createTemporaryDirectory(template);

          expect(resultPath, isNotNull);
          expect(resultPath, isNotEmpty);
          expect(resultPath, startsWith(templatePrefix));
          expect(resultPath.length, template.length);
          expect(resultPath.substring(resultPath.length - 6), isNot('XXXXXX'));
          // Cannot reliably check for actual directory existence here,
          // but success implies mkdtemp worked.
          // In a real environment, we might clean up here, but it's complex
          // in this test setup.
        });

        test('throws PathNotFoundException for non-existent parent directory',
            () {
          const template = '/no/such/directory/test.XXXXXX';
          expect(
            () => fs.createTemporaryDirectory(template),
            throwsA(isA<PathNotFoundException>()),
            reason: 'mkdtemp should fail with ENOENT for invalid paths.',
          );
        });

        test('throws FileSystemException for template without XXXXXX suffix',
            () {
          const template = '/tmp/io_file_test_no_suffix';
          expect(
            () => fs.createTemporaryDirectory(template),
            throwsA(isA<FileSystemException>().having(
                (e) => e.osError?.errorCode, 'osError.errorCode', isNot(0))),
            reason: 'mkdtemp requires the XXXXXX suffix and should fail.',
          );
        });

        // TODO(brianquinlan): add tests for permissions/access issues once
        // those error codes are mapped correctly in _getError.
      }); // group createTemporaryDirectory
    }); // group PosixFileSystem
  } // if POSIX platform
}
