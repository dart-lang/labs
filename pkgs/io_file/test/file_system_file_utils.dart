import 'package:io_file/io_file.dart';

import 'test_utils.dart';

/// File utilities implemented using [FileSystem].
///
/// Used to verify the behavior of mocks and other implementations that may not
/// touch the platform file system.
class FileSystemFileUtils implements FileUtils {
  final FileSystem fs;

  FileSystemFileUtils([FileSystem? fs]) : fs = fs ?? fileSystem;

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
  bool isDirectory(String path) => fs.metadata(path).isDirectory;
}

FileUtils fileUtils() => FileSystemFileUtils();
