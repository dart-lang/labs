// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('windows') // These tests are Windows-specific due to symlinks/junctions and the implementation

import 'dart:io';

import 'package:io_file/io_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir; // Holds the unique temporary directory for each test
  final fs = WindowsFileSystem(); // Instance of the class under test

  setUp(() {
    // Create a unique temporary directory for this test.
    tempDir = Directory.systemTemp.createTempSync('io_file_test_delete_recursive_');
  });

  tearDown(() {
    // Clean up the temporary directory.
    try {
      if (tempDir.existsSync()) {
        // Use Dart's deleteSync for cleanup, assuming it handles complexity,
        // or potentially call the fs under test again if needed.
        // Sticking to Dart's deleteSync for robust cleanup.
        tempDir.deleteSync(recursive: true);
      }
    } catch (e) {
      // Ignore errors during cleanup, e.g., if the test deleted it.
      print('Ignoring error during tearDown: $e');
    }
  });

  group('WindowsFileSystem.deleteDirectoryRecursively', () {
    test('deletes an empty directory', () {
      final dirPath = p.join(tempDir.path, 'empty_dir');
      Directory(dirPath).createSync();
      expect(Directory(dirPath).existsSync(), isTrue);

      fs.deleteDirectoryRecursively(dirPath);

      expect(Directory(dirPath).existsSync(), isFalse);
      // Verify the parent tempDir still exists
      expect(tempDir.existsSync(), isTrue);
    });

    test('deletes a directory with files', () {
      final dirPath = p.join(tempDir.path, 'dir_with_files');
      final file1Path = p.join(dirPath, 'file1.txt');
      final file2Path = p.join(dirPath, 'file2.bin');

      Directory(dirPath).createSync();
      File(file1Path).writeAsStringSync('content1');
      File(file2Path).writeAsBytesSync([1, 2, 3]);

      expect(Directory(dirPath).existsSync(), isTrue);
      expect(File(file1Path).existsSync(), isTrue);
      expect(File(file2Path).existsSync(), isTrue);

      fs.deleteDirectoryRecursively(dirPath);

      expect(Directory(dirPath).existsSync(), isFalse);
      expect(File(file1Path).existsSync(), isFalse);
      expect(File(file2Path).existsSync(), isFalse);
      expect(tempDir.existsSync(), isTrue);
    });

     test('deletes nested directories and files', () {
      final dirPath = p.join(tempDir.path, 'nested_dir');
      final subDirPath = p.join(dirPath, 'subdir');
      final filePath1 = p.join(dirPath, 'file1.txt');
      final filePath2 = p.join(subDirPath, 'file2.txt');

      Directory(subDirPath).createSync(recursive: true);
      File(filePath1).writeAsStringSync('content1');
      File(filePath2).writeAsStringSync('content2');

      expect(Directory(dirPath).existsSync(), isTrue);
      expect(Directory(subDirPath).existsSync(), isTrue);
      expect(File(filePath1).existsSync(), isTrue);
      expect(File(filePath2).existsSync(), isTrue);

      fs.deleteDirectoryRecursively(dirPath);

      expect(Directory(dirPath).existsSync(), isFalse);
      expect(Directory(subDirPath).existsSync(), isFalse); // Should be gone
      expect(File(filePath1).existsSync(), isFalse);
      expect(File(filePath2).existsSync(), isFalse);
      expect(tempDir.existsSync(), isTrue);
    });

    test('deletes directory with a file symlink, leaves target', () {
      final targetFilePath = p.join(tempDir.path, 'target_file.txt');
      final dirToDeletePath = p.join(tempDir.path, 'dir_with_link');
      final linkPath = p.join(dirToDeletePath, 'link.txt');

      File(targetFilePath).writeAsStringSync('target content');
      Directory(dirToDeletePath).createSync();
      Link(linkPath).createSync(targetFilePath); // File symlink

      expect(File(targetFilePath).existsSync(), isTrue);
      expect(Directory(dirToDeletePath).existsSync(), isTrue);
      expect(Link(linkPath).existsSync(), isTrue);
      expect(FileSystemEntity.typeSync(linkPath), FileSystemEntityType.link);
      expect(Link(linkPath).targetSync(), targetFilePath);

      fs.deleteDirectoryRecursively(dirToDeletePath);

      expect(Directory(dirToDeletePath).existsSync(), isFalse, reason: 'Directory should be deleted');
      expect(Link(linkPath).existsSync(), isFalse, reason: 'Link should be deleted');
      expect(File(targetFilePath).existsSync(), isTrue, reason: 'Target file should remain');
      expect(tempDir.existsSync(), isTrue);
    });

    test('deletes directory with a directory symlink, leaves target', () {
      final targetDirPath = p.join(tempDir.path, 'target_dir');
      final dirToDeletePath = p.join(tempDir.path, 'dir_with_dir_link');
      final linkPath = p.join(dirToDeletePath, 'link_dir');

      Directory(targetDirPath).createSync();
      File(p.join(targetDirPath, 'inside.txt')).writeAsStringSync('in target');
      Directory(dirToDeletePath).createSync();

      try {
        Link(linkPath).createSync(targetDirPath); // Directory symlink
      } on FileSystemException catch (e) {
        // Creating directory symlinks might require SeCreateSymbolicLinkPrivilege
        // or developer mode enabled on Windows 10+. Skip if creation fails.
        print('Skipping directory symlink test: Failed to create link ($e)');
        return; // Skip the rest of the test
      }

      expect(Directory(targetDirPath).existsSync(), isTrue);
      expect(File(p.join(targetDirPath, 'inside.txt')).existsSync(), isTrue);
      expect(Directory(dirToDeletePath).existsSync(), isTrue);
      expect(Link(linkPath).existsSync(), isTrue);
      expect(FileSystemEntity.typeSync(linkPath), FileSystemEntityType.link);
      // Note: Link.targetSync() might resolve recursively on some platforms/versions
      // We primarily care that the link exists and points *somewhere* initially.

      fs.deleteDirectoryRecursively(dirToDeletePath);

      expect(Directory(dirToDeletePath).existsSync(), isFalse, reason: 'Directory should be deleted');
      expect(Link(linkPath).existsSync(), isFalse, reason: 'Link should be deleted');
      expect(Directory(targetDirPath).existsSync(), isTrue, reason: 'Target directory should remain');
      expect(File(p.join(targetDirPath, 'inside.txt')).existsSync(), isTrue, reason: 'Target content should remain');
      expect(tempDir.existsSync(), isTrue);
    });

    test('deletes directory with a junction, leaves target', () {
      final targetDirPath = p.join(tempDir.path, 'target_junction_dir');
      final dirToDeletePath = p.join(tempDir.path, 'dir_with_junction');
      final junctionPath = p.join(dirToDeletePath, 'junction_dir');

      Directory(targetDirPath).createSync();
      File(p.join(targetDirPath, 'inside_junction.txt')).writeAsStringSync('in junction target');
      Directory(dirToDeletePath).createSync();

      // Create Junction (using recursive: true for Link.createSync)
      Link(junctionPath).createSync(targetDirPath, recursive: true);

      expect(Directory(targetDirPath).existsSync(), isTrue);
      expect(File(p.join(targetDirPath, 'inside_junction.txt')).existsSync(), isTrue);
      expect(Directory(dirToDeletePath).existsSync(), isTrue);
      expect(Link(junctionPath).existsSync(), isTrue); // Junctions appear as links
      expect(FileSystemEntity.typeSync(junctionPath), FileSystemEntityType.link);

      fs.deleteDirectoryRecursively(dirToDeletePath);

      expect(Directory(dirToDeletePath).existsSync(), isFalse, reason: 'Directory should be deleted');
      expect(Link(junctionPath).existsSync(), isFalse, reason: 'Junction should be deleted');
      expect(Directory(targetDirPath).existsSync(), isTrue, reason: 'Target directory should remain');
      expect(File(p.join(targetDirPath, 'inside_junction.txt')).existsSync(), isTrue, reason: 'Target content should remain');
      expect(tempDir.existsSync(), isTrue);
    });

    test('completes successfully for non-existent path', () {
      final nonExistentPath = p.join(tempDir.path, 'does_not_exist');
      expect(Directory(nonExistentPath).existsSync(), isFalse);

      // Expect the call to complete without throwing an error.
      expect(() => fs.deleteDirectoryRecursively(nonExistentPath), returnsNormally);

      expect(Directory(nonExistentPath).existsSync(), isFalse); // Still doesn't exist
    });

    test('throws FileSystemException when called on a file path', () {
      final filePath = p.join(tempDir.path, 'just_a_file.txt');
      File(filePath).writeAsStringSync('i am a file');
      expect(File(filePath).existsSync(), isTrue);

      // The underlying RemoveDirectoryW call on the file path should fail.
      // Expecting a generic FileSystemException, as specific error code mapping might vary.
      // Windows error ERROR_DIRECTORY (267) is likely.
      expect(
            () => fs.deleteDirectoryRecursively(filePath),
        throwsA(isA<FileSystemException>()),
      );

      // Ensure the file was not deleted
      expect(File(filePath).existsSync(), isTrue);
    });

    // Optional: Test for very long paths if relevant and feasible.
    // test('handles very long paths (> MAX_PATH)', () { ... });
  });
}
