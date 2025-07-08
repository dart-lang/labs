import 'dart:io';

import 'test_utils.dart';

/// File utilities implemented using `dart:io`.
///
/// Used to verify `package:io_file` behavior against an external reference.
class DartIOFileUtils implements FileUtils {
  @override
  String createTestDirectory(String testName) =>
      Directory.systemTemp.createTempSync(testName).absolute.path;

  @override
  void deleteDirectoryTree(String path) =>
      Directory(path).deleteSync(recursive: true);

  @override
  bool isDirectory(String path) => FileSystemEntity.isDirectorySync(path);

  @override
  void createDirectory(String path) => Directory(path).createSync();

  @override
  void createTextFile(String path, String s) => File(path).writeAsStringSync(s);
}

FileUtils fileUtils() => DartIOFileUtils();
