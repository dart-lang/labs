import 'dart:io';

import 'test_utils.dart';

class NativeTestUtils implements TestUtils {
  @override
  String createTestDirectory(String testName) =>
      Directory.systemTemp.createTempSync(testName).absolute.path;

  @override
  void deleteDirectoryTree(String path) =>
      Directory(path).deleteSync(recursive: true);

  @override
  bool isDir(String path) => FileSystemEntity.isDirectorySync(path);

  @override
  void createDirectory(String path) => Directory(path).createSync();

  @override
  void createTextFile(String path, String s) => File(path).writeAsStringSync(s);
}

TestUtils testUtils() => NativeTestUtils();
