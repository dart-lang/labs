import 'dart:convert';

import 'dart:typed_data';

import 'file_system.dart';
import 'posix_file_system.dart';

final class FakePosixFileSystem extends PosixFileSystem {
  @override
  void createDirectory(String path) {
    // TODO: implement createDirectory
  }

  @override
  String createTemporaryDirectory({String? parent, String? prefix}) {
    // TODO: implement createTemporaryDirectory
    throw UnimplementedError();
  }

  @override
  Metadata metadata(String path) {
    // TODO: implement metadata
    throw UnimplementedError();
  }

  @override
  Uint8List readAsBytes(String path) {
    // TODO: implement readAsBytes
    throw UnimplementedError();
  }

  @override
  void removeDirectory(String path) {
    // TODO: implement removeDirectory
  }

  @override
  void removeDirectoryTree(String path) {
    // TODO: implement removeDirectoryTree
  }

  @override
  void rename(String oldPath, String newPath) {
    // TODO: implement rename
  }

  @override
  bool same(String path1, String path2) {
    // TODO: implement same
    throw UnimplementedError();
  }

  @override
  void writeAsBytes(
    String path,
    Uint8List data, [
    WriteMode mode = WriteMode.failExisting,
  ]) {
    // TODO: implement writeAsBytes
  }

  @override
  void writeAsString(
    String path,
    String contents, [
    WriteMode mode = WriteMode.failExisting,
    Encoding encoding = utf8,
    String? lineTerminator,
  ]) {
    // TODO: implement writeAsString
  }
}
