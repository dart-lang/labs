import 'package:io_file/io_file.dart';

import 'test_utils.dart';

class SelfTestUtils implements TestUtils {
  final FileSystem fs;

  SelfTestUtils([FileSystem? fs]) : fs = fs ?? fileSystem;

  @override
  void createDirectory(String path) {
    fs.createDirectory(path);
  }

  @override
  String createTestDirectory(String testName) =>
      fs.createTemporaryDirectory(prefix: testName);

  @override
  void createTextFile(String path, String s) {
    fs.writeAsString(path, s);
  }

  @override
  void deleteDirectoryTree(String path) {
    fs.removeDirectoryTree(path);
  }

  @override
  bool isDir(String path) => fs.metadata(path).isDirectory;
}

TestUtils testUtils() => SelfTestUtils();
