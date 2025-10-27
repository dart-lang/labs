// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:jot/api.dart';
import 'package:jot/src/analysis.dart';
import 'package:jot/src/html.dart';
import 'package:jot/src/render.dart';
import 'package:jot/workspace.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

@isTest
void testWithSource(
  String description,
  String source,
  void Function(TestProject) body,
) {
  test(description, () async {
    final project = TestProject({'main.dart': source});

    try {
      await project.init();

      body(project);
    } finally {
      project.dispose();
    }
  });
}

class TestProject {
  final Directory dir;
  final Map<String, String> sources;

  late final Workspace workspace;
  late final Analyzer analyzer;

  TestProject(this.sources) : dir = Directory.systemTemp.createTempSync();

  factory TestProject.fromTemplate(Directory dir) {
    final libDir = Directory(p.join(dir.path, 'lib'));
    final files = libDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    return TestProject({
      for (var file in files)
        p.relative(file.path, from: libDir.path): file.readAsStringSync(),
    });
  }

  String get libDirPath => p.join(dir.path, 'lib');

  Directory get outDir => Directory(p.join(dir.path, 'doc', 'api'));

  Resolver get resolver => workspace.api.resolver;

  List<LibraryItemContainer> get libraries =>
      workspace.api.packages.first.libraries;

  LibraryItemContainer get firstLibrary => libraries.first;

  Item get firstItem => firstLibrary.allChildren.first;

  Item itemNamed(String name) =>
      firstLibrary.allChildren.firstWhere((item) => item.element.name == name);

  Items get firstInterfaceItem =>
      firstLibrary.allChildren.firstWhere(
            (item) => item.element is InterfaceElement,
          )
          as Items;

  Items classNamed(String name) =>
      firstLibrary.allChildren.firstWhere(
            (item) =>
                item.element is InterfaceElement && item.element.name == name,
          )
          as Items;

  Items extensionTypeNamed(String name) =>
      firstLibrary.allChildren.firstWhere(
            (item) =>
                // ignore: experimental_member_use
                item.element is ExtensionTypeElement &&
                item.element.name == name,
          )
          as Items;

  LinkedCodeRenderer rendererFor(Item item) {
    return LinkedCodeRenderer(resolver, resolver.fileFor(item.element)!);
  }

  void _create() {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    pubspec.writeAsStringSync('name: testing');

    Directory(libDirPath).createSync();

    for (final entry in sources.entries) {
      final file = File(p.join(libDirPath, entry.key));
      file.writeAsStringSync(entry.value);
    }
  }

  Future<void> init() async {
    _create();

    final htmlTemplate = await HtmlTemplate.createDefault();
    workspace = Workspace.fromPackage(htmlTemplate, dir);
    var packageName = workspace.name.substring('package:'.length);

    analyzer = Analyzer.packages(
      includedPaths: [p.normalize(dir.absolute.path)],
    );

    await for (var resolvedLibrary in analyzer.resolvedPublicLibraries()) {
      var libraryPath = resolvedLibrary.element.source.fullName;

      var dartLibraryPath = p.relative(libraryPath, from: libDirPath);
      var htmlOutputPath = '${p.withoutExtension(dartLibraryPath)}.html';

      var libraryContainer = workspace.addChild(
        WorkspaceDirectory(workspace, dartLibraryPath),
      );

      var library = workspace.api.addLibrary(
        resolvedLibrary.element,
        workspace.name,
        dartLibraryPath,
      );

      libraryContainer.mainFile = WorkspaceFile(
        workspace,
        dartLibraryPath,
        htmlOutputPath,
        emptyContentGenerator,
      )..importScript = 'package:$packageName/$dartLibraryPath';

      workspace.api.addResolution(library, libraryContainer.mainFile!);

      for (var itemContainer in library.allChildrenSorted.whereType<Items>()) {
        var path =
            '${p.withoutExtension(dartLibraryPath)}/${itemContainer.name}.html';
        var docFile = WorkspaceFile(
          libraryContainer,
          itemContainer.name,
          path,
          emptyContentGenerator,
        );
        libraryContainer.addChild(docFile);
        workspace.api.addResolution(itemContainer, docFile);
      }
    }

    workspace.api.finish();
  }

  void dispose() {
    dir.deleteSync(recursive: true);
  }
}

class NullLogger implements Logger {
  final Ansi _ansi = Ansi(false);

  @override
  Ansi get ansi => _ansi;

  @override
  void flush() {}

  @override
  bool get isVerbose => false;

  @override
  Progress progress(String message) => NullProgress(message);

  @override
  void stderr(String message) {}

  @override
  void stdout(String message) {}

  @override
  void trace(String message) {}

  @override
  void write(String message) {}

  @override
  void writeCharCode(int charCode) {}
}

class NullProgress implements Progress {
  @override
  final String message;

  final Stopwatch _timer = Stopwatch()..start();

  NullProgress(this.message);

  @override
  void cancel() {}

  @override
  Duration get elapsed => _timer.elapsed;

  @override
  void finish({String? message, bool showTiming = false}) {
    _timer.stop();
  }
}
