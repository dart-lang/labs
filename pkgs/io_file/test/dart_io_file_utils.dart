import 'dart:io';
import 'dart:typed_data';

import 'test_utils.dart';

/// File utilities implemented using `dart:io`.
///
/// Used to verify `package:io_file` behavior against an external reference.
class DartIOFileUtils implements FileUtils {
  @override
  void createBinaryFile(String path, Uint8List b) =>
      File(path).writeAsBytesSync(b);

  @override
  String createTestDirectory(String testName) =>
      Directory.systemTemp.createTempSync(testName).absolute.path;

  @override
  void deleteDirectoryTree(String path) =>
      Directory(path).deleteSync(recursive: true);

  @override
  bool exists(String path) =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  @override
  bool isDirectory(String path) => FileSystemEntity.isDirectorySync(path);

  @override
  void createDirectory(String path) => Directory(path).createSync();

  @override
  void deleteDirectory(String path) => Directory(path).deleteSync();

  @override
  void createTextFile(String path, String s) => File(path).writeAsStringSync(s);

  @override
  Uint8List readBinaryFile(String path) => File(path).readAsBytesSync();
}

FileUtils fileUtils() => DartIOFileUtils();
