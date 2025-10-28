// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' as convert;
import 'dart:io';

import 'package:path/path.dart' as p;

String stripDartdoc(String str) {
  str = str.trim();

  if (str.startsWith('/**')) {
    str = str.substring('/**'.length);
    if (str.endsWith('*/')) str = str.substring(0, str.length - '*/'.length);
    return str
        .split('\n')
        .map((line) => line.trimLeft())
        .map((line) {
          if (line.startsWith('* ')) return line.substring(2);
          if (line.startsWith('*')) return line.substring(1);
          return line;
        })
        .map((line) => line.trimRight())
        .skipWhile((l) => l.trim().isEmpty)
        .join('\n');
  } else {
    return str
        .split('\n')
        .map((line) => line.trimLeft())
        .map((line) {
          if (line.startsWith('/// ')) return line.substring(4);
          if (line.startsWith('///')) return line.substring(3);
          return line;
        })
        .map((line) => line.trimRight())
        .join('\n');
  }
}

String titleCase(String str) {
  return str.substring(0, 1).toUpperCase() + str.substring(1);
}

String htmlEscape(String text) => convert.htmlEscape.convert(text);

/// Returns an adjusted lexical compare.
///
/// Adjustments include sorting case-insensitive.
int adjustedLexicalCompare(String a, String b) {
  if (a.isEmpty || b.isEmpty) return a.compareTo(b);

  var lowerA = a.toLowerCase();
  var lowerB = b.toLowerCase();

  return lowerA.compareTo(lowerB);
}

String stringToAnchorId(String str) => Uri.encodeQueryComponent(str);

typedef _JsonType = Map<String, dynamic>;

String? getPackageRoot(Directory fromDir, String packageName) {
  var packageFile = _findPackageConfig(fromDir);
  if (packageFile == null) return null;

  var packageInfo =
      convert.jsonDecode(packageFile.readAsStringSync()) as _JsonType;
  for (var info in packageInfo['packages'] as List<_JsonType>) {
    if (info['name'] == packageName) {
      return File.fromUri(Uri.parse(info['rootUri'] as String)).path;
    }
  }

  return null;
}

File? _findPackageConfig(Directory dir) {
  var file = File(p.join(dir.path, '.dart_tool', 'package_config.json'));
  if (file.existsSync()) return file;

  return dir.parent == dir ? null : _findPackageConfig(dir.parent);
}

extension DirectoryExtension on Directory {
  List<FileSystemEntity> listSyncSorted({bool recursive = false}) {
    var entites = listSync(recursive: recursive);
    entites.sort((a, b) => adjustedLexicalCompare(a.path, b.path));
    return entites;
  }
}

extension FileSystemEntityExtension on FileSystemEntity {
  String get name => p.basename(path);
}

extension FileExtension on File {
  bool get publicMarkdownFile =>
      !name.startsWith('_') && p.extension(path) == '.md';
}

class Outline {
  final List<Heading> items = [];

  void add(Heading heading) {
    if (items.isEmpty) {
      items.add(heading);
    } else if (items.last.level >= heading.level) {
      items.add(heading);
    } else {
      items.last.add(heading);
    }
  }

  String get asHtml {
    var buf = StringBuffer(
      '<ul class="table-of-contents table-of-contents__left-border">\n',
    );
    for (var item in items) {
      buf.writeln(item.asHtml);
    }
    buf.write('</ul>');
    return buf.toString();
  }
}

class Heading {
  final String label;
  final String? id;
  final int level;

  final List<Heading> children = [];

  Heading(this.label, {this.id, this.level = 2});

  void add(Heading heading) {
    if (children.isEmpty) {
      children.add(heading);
    } else if (children.last.level >= heading.level) {
      children.add(heading);
    } else {
      children.last.add(heading);
    }
  }

  String get asHtml {
    var buf = StringBuffer('<li>');
    var href = id == null ? '' : 'href="#$id"';
    buf.write(
      '<a class="table-of-contents__link toc-highlight" $href>$label</a>',
    );
    if (children.isNotEmpty) {
      buf.writeln();
      buf.writeln('<ul>');
      for (var child in children) {
        buf.writeln(child.asHtml);
      }
      buf.writeln('</ul>');
    }
    buf.write('</li>');
    return buf.toString();
  }

  @override
  String toString() => id == null ? '$label h$level' : '$label h$level ($id)';
}

class Stats {
  final Stopwatch timer = Stopwatch();
  int fileCount = 0;
  int byteCount = 0;

  void start() {
    timer.start();
  }

  void genFile(File file) {
    fileCount++;
    byteCount += file.lengthSync();
  }

  String get elapsedSeconds =>
      (timer.elapsedMilliseconds / 1000.0).toStringAsFixed(1);

  String get sizeDesc {
    const bytesPerMB = 1024.0 * 1024;

    if (byteCount >= bytesPerMB) {
      return '${(byteCount / (1024.0 * 1024.0)).toStringAsFixed(1)}MB';
    } else {
      return '${byteCount ~/ 1024.0}k';
    }
  }

  void stop() {
    timer.stop();
  }
}

extension StringExtension on String {
  /// A simple implementation of `package:path`'s `relative` function.
  ///
  /// The implementation from `package:path` ends up calling `Directory.current`
  /// enough that that call along can account for 60% of this tool's run time.
  String pathRelative({required String fromDir}) {
    if (fromDir.isEmpty || fromDir == '.') {
      return this;
    }

    var paths = split('/');
    var froms = fromDir.split('/');

    while (paths.isNotEmpty && froms.isNotEmpty && paths.first == froms.first) {
      paths = paths.sublist(1);
      froms = froms.sublist(1);
    }

    for (var _ in froms) {
      paths.insert(0, '..');
    }

    return paths.join('/');
  }
}
