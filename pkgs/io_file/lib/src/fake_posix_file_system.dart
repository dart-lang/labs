import 'dart:convert';

import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'exceptions.dart';
import 'file_system.dart';
import 'posix_file_system.dart';

sealed class _Entity {}

class _File extends _Entity {
  _File();
}

class _Directory extends _Entity {
  final children = <String, _Entity>{};

  @override
  String toString() => '<Directory children=$children>';
}

class _FakeMetadata implements PosixMetadata {
  @override
  DateTime get access => throw UnimplementedError();

  @override
  DateTime? get creation => throw UnimplementedError();

  @override
  bool get isDirectory => this.type == FileSystemType.directory;

  @override
  bool get isFile => throw UnimplementedError();

  @override
  bool? get isHidden => throw UnimplementedError();

  @override
  bool get isLink => throw UnimplementedError();

  @override
  DateTime get modification => throw UnimplementedError();

  @override
  int get size => throw UnimplementedError();

  @override
  final FileSystemType type;

  _FakeMetadata(this.type);

  @override
  int get accessedTimeNanos => throw UnimplementedError();

  @override
  int? get creationTimeNanos => throw UnimplementedError();

  @override
  int get modificationTimeNanos => throw UnimplementedError();
}

final class FakePosixFileSystem extends PosixFileSystem {
  final context = p.Context(style: p.Style.posix);
  final root = _Directory();
  final tmp = _Directory();

  FakePosixFileSystem() {
    print('Reset!');
    root.children['tmp'] = tmp;
  }

  _Entity? _findComponents(List<String> components) {
    _Entity e = root;
    for (var child in components.skip(1)) {
      print('$child => $e');
      if (e is _Directory) {
        if (!e.children.containsKey(child)) return null;
        e = e.children[child]!;
      } else {
        return null;
      }
    }
    return e;
  }

  _Entity? _findEntity(String path) {
    path = context.absolute(path);
    return _findComponents(p.split(path));
  }

  _Entity? _upToLast(String path) {
    path = context.absolute(path);
    return _findComponents(p.split(p.dirname(path)));
  }

  @override
  void createDirectory(String path) {
    print('createDirectory($path)');
    if (_findEntity(path) != null) {
      throw PathExistsException(
        'create directory failed',
        path: path,
        systemCall: const SystemCallError('XXX', 17, 'XXX'),
      );
    }
    path = context.absolute(path);
    final base = context.basename(path);

    final parent = _upToLast(path);
    print('parent $parent');
    if (parent is _Directory) {
      parent.children[base] = _Directory();
    } else if (parent == null) {
      throw PathNotFoundException(
        'create directory failed',
        path: path,
        systemCall: const SystemCallError('XXX', 2, 'XXX'),
      );
    } else {
      throw UnsupportedError(path);
    }
  }

  @override
  String createTemporaryDirectory({String? parent, String? prefix}) {
    final parentDir = parent ?? '/tmp';

    String path = p.join(parentDir, prefix);
    createDirectory(path);
    return path;
  }

  @override
  Metadata metadata(String path) {
    final e = _findEntity(path);
    return _FakeMetadata(switch (e) {
      _Directory() => FileSystemType.directory,
      _File() => FileSystemType.file,
      _ => FileSystemType.unknown,
    });
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
    final parent = _upToLast(path);
    final base = context.basename(path);

    if (parent is _Directory) {
      if (parent.children.containsKey(base)) {
        // Check that it is a directory.
        parent.children.remove(base);
      } else {
        throw UnsupportedError('XXX');
      }
    } else {
      throw UnsupportedError('XXX');
    }
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
    final parent = _upToLast(path);
    final base = context.basename(path);

    if (parent is _Directory) {
      // Do something with the file contents.
      parent.children[base] = _File();
    } else {
      throw UnsupportedError('XXX');
    }
  }
}
