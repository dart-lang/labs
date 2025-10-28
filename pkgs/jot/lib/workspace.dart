// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Used to model the desired generation output.
///
/// See [Workspace].
library;

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;

import 'api.dart';
import 'src/html.dart';
import 'src/markdown.dart';
import 'src/utils.dart';

typedef FileContentGenerator =
    Future<GenerationResults> Function(
      Workspace workspace,
      WorkspaceFile thisFile,
    );

class GenerationResults {
  final String contents;
  final Outline? outline;

  GenerationResults(this.contents, [this.outline]);
}

Future<GenerationResults> emptyContentGenerator(
  Workspace workspace,
  WorkspaceFile thisFile,
) {
  return Future.value(GenerationResults(''));
}

FileContentGenerator createMarkdownGenerator(File markdownFile) {
  return (Workspace workspace, WorkspaceFile thisFile) async {
    var content = markdownFile.readAsStringSync();
    var results = convertMarkdownWithOutline(content);
    return GenerationResults(results.html, results.outline);
  };
}

abstract class WorkspaceEntity {
  final WorkspaceEntity? parent;
  final String name;

  WorkspaceEntity(this.parent, this.name);

  WorkspaceFile? get mainFile;

  Workspace get workspace => parent!.workspace;

  WorkspaceDirectory? get parentPackage => parent?.parentPackage;

  Iterable<WorkspaceEntity> get breadcrumbs {
    var result = <WorkspaceEntity>[];
    WorkspaceEntity? item = this;

    while (item != null) {
      if (item is WorkspaceFile) {
        result.add(item);
      } else if (item is WorkspaceDirectory) {
        if (item.mainFile != null && !result.contains(item.mainFile)) {
          result.add(item.mainFile!);
        }
      }
      item = item.parent;
    }

    return result.reversed;
  }

  @override
  String toString() => name;
}

class WorkspaceFile extends WorkspaceEntity {
  final String path;
  final FileContentGenerator contentGenerator;
  final FileType fileType;

  /// If set, the script to specify in an import.
  String? importScript;

  WorkspaceFile(
    super.parent,
    super.name,
    this.path,
    this.contentGenerator, [
    this.fileType = FileType.dart,
  ]);

  bool get isMarkdown => fileType == FileType.markdown;

  @override
  WorkspaceFile? get mainFile => this;

  Future<GenerationResults> generatePageContents() {
    return contentGenerator(workspace, this);
  }

  @override
  String toString() => 'DocFile $name';
}

enum FileType { markdown, dart }

class WorkspaceSeparator extends WorkspaceEntity {
  WorkspaceSeparator(super.parent, super.name);

  @override
  WorkspaceFile? get mainFile => null;
}

class WorkspaceDirectory extends WorkspaceEntity {
  // todo: is isGroup used? an important distinction?
  final bool isGroup;
  final bool isPackage;

  final List<WorkspaceEntity> children = [];

  String? version;
  String? description;

  @override
  WorkspaceFile? mainFile;

  WorkspaceDirectory(
    super.parent,
    super.name, {
    this.isGroup = false,
    this.isPackage = false,
  }) {
    // TODO: have a default mainfile?
  }

  int get itemCount {
    var count = mainFile == null ? 0 : 1;
    for (var child in children) {
      if (child is WorkspaceDirectory) {
        count += child.itemCount;
      } else {
        count++;
      }
    }
    return count;
  }

  @override
  WorkspaceDirectory? get parentPackage =>
      isPackage ? this : parent?.parentPackage;

  T addChild<T extends WorkspaceEntity>(T entity) {
    children.add(entity);
    return entity;
  }

  WorkspaceEntity? getChild(String name) {
    return children.firstWhereOrNull((c) => c.name == name);
  }

  @override
  String toString() => 'DocContainer $name';

  bool hasChild(WorkspaceFile page) {
    if (mainFile == page) return true;
    if (children.contains(page)) return true;
    return false;
  }
}

/// A model of the generation output.
class Workspace extends WorkspaceDirectory {
  final Api api = Api();
  final HtmlTemplate htmlTemplate;
  final List<WorkspaceFile> navFiles = [];

  String? footer;

  Workspace(String name, {super.isPackage, required this.htmlTemplate})
    : super(null, name) {
    // Placeholder for the main file.
    mainFile = WorkspaceFile(
      this,
      'index.html',
      'index.html',
      emptyContentGenerator,
      FileType.markdown,
    );
  }

  @override
  Workspace get workspace => this;

  final Map<String, Map<String, String>> _pathToCache = {};

  String pathTo(WorkspaceFile target, {WorkspaceFile? from}) {
    if (from == null) return target.path;

    var to = target.path;
    var fromDir = p.dirname(from.path);

    var fromCache = _pathToCache.putIfAbsent(fromDir, () => {});
    return fromCache.putIfAbsent(to, () {
      // We use our own custom 'relative' implementation as the package:path one
      // obsessively call's Directory.current, and would contribute as much as
      // 60% of our run time.
      return to.pathRelative(fromDir: fromDir);
      // return p.relative(target.path, from: p.dirname(from.path));
    });
  }

  Future<String> generateWorkspacePage(
    WorkspaceFile file,
    GenerationResults page,
  ) async {
    // navbar
    var navbarContent = [mainFile!, ...navFiles]
        .map((target) {
          var active = '';
          if (navFiles.contains(file) && target == file) {
            active = ' navbar__link--active';
          } else if (!navFiles.contains(file) && target == mainFile) {
            active = ' navbar__link--active';
          }

          var href = 'href="${pathTo(target, from: file)}"';
          var name = target == mainFile ? 'Docs' : target.name;
          return '<a $href class="navbar__item navbar__link$active" data-jot>$name</a>';
        })
        .join(' ');

    // breadcrumbs
    var breadcrumbs = file.breadcrumbs;
    if (breadcrumbs.length == 1) {
      breadcrumbs = [];
    }
    var breadcrumbsContent = breadcrumbs
        .map((entity) {
          var target = entity is WorkspaceFile
              ? entity
              : (entity as WorkspaceDirectory).mainFile!;
          var href = 'href="${pathTo(target, from: file)}"';

          if (workspace.mainFile == target) {
            return '''
          <li class="breadcrumbs__item">
            <a class="breadcrumbs__link" $href>
              <svg viewBox="0 0 24 24" class="breadcrumbHomeIcon">
                <path
                  d="M10 19v-5h4v5c0 .55.45 1 1 1h3c.55 0 1-.45 1-1v-7h1.7c.46 0 .68-.57.33-.87L12.67 3.6c-.38-.34-.96-.34-1.34 0l-8.36 7.53c-.34.3-.13.87.33.87H5v7c0 .55.45 1 1 1h3c.55 0 1-.45 1-1z"
                  fill="currentColor">
                </path>
              </svg>
            </a>
          </li>''';
          } else if (file == target) {
            return '<li class="breadcrumbs__item breadcrumbs__item--active">'
                '<span class="breadcrumbs__link">${entity.name}</span></li>';
          } else {
            return '<li class="breadcrumbs__item">'
                '<a $href class="breadcrumbs__link">${entity.name}</a></li>';
          }
        })
        .join(' ');

    var pathPrefix = p
        .split(file.path)
        .skip(1)
        .map((e) => '..')
        .join(p.separator);
    if (pathPrefix.isNotEmpty) pathPrefix = '$pathPrefix/';

    return htmlTemplate.templateSubtitute(
      pageTitle: name,
      pathPrefix: pathPrefix,
      pageRef: file.path,
      navbar: navbarContent,
      breadcrumbs: breadcrumbsContent,
      pageContent: page.contents.trimRight(),
      toc: page.outline?.asHtml ?? '',
      footer: footer ?? '',
    );
  }

  String generateNavData() {
    const encoder = JsonEncoder.withIndent('');

    var navItems = [mainFile!, ...children].map(_generateNavData).toList();
    return encoder.convert(navItems);
  }

  Map<String, dynamic> _generateNavData(WorkspaceEntity page) {
    if (page is WorkspaceFile) {
      return {'n': page.name, 'h': page.path};
    } else if (page is WorkspaceSeparator) {
      return {'n': page.name, 't': 'separator'};
    } else if (page is WorkspaceDirectory) {
      final mainFile = page.mainFile!;

      return {
        'n': mainFile.name,
        'h': mainFile.path,
        'c': page.children.map(_generateNavData).toList(),
      };
    } else {
      throw StateError('unexpected subclass');
    }
  }

  @override
  String toString() => 'DocWorkspace $name';

  static Workspace fromPackage(HtmlTemplate htmlTemplate, Directory dir) {
    var pubspec =
        yaml.loadYaml(File(p.join(dir.path, 'pubspec.yaml')).readAsStringSync())
            as yaml.YamlMap;

    final packageName = pubspec['name'] as String?;
    final packageVersion = pubspec['version'] as String?;

    var workspace = Workspace(
      'package:$packageName',
      htmlTemplate: htmlTemplate,
      isPackage: true,
    );
    workspace.version = packageVersion;
    if (packageVersion != null) {
      workspace.footer = 'package:$packageName v$packageVersion';
    }
    workspace.description = pubspec['description'] as String?;

    for (var file in dir.listSyncSorted().whereType<File>().where(
      (f) => f.publicMarkdownFile,
    )) {
      var name = p.relative(file.path, from: dir.path);
      var title = titleCase(
        p.basenameWithoutExtension(file.path).toLowerCase(),
      );

      var path = '${p.withoutExtension(name)}.html';
      if (name == 'README.md') {
        workspace.mainFile = WorkspaceFile(
          workspace,
          title,
          'index.html',
          createMarkdownGenerator(file),
          FileType.markdown,
        );
      } else if (name == 'CHANGELOG.md' || name == 'LICENSE.md') {
        workspace.navFiles.add(
          WorkspaceFile(
            workspace,
            title,
            path,
            createMarkdownGenerator(file),
            FileType.markdown,
          ),
        );
      } else {
        workspace.addChild(
          WorkspaceFile(
            workspace,
            title,
            path,
            createMarkdownGenerator(file),
            FileType.markdown,
          ),
        );
      }
    }

    var docDir = Directory(p.join(dir.path, 'doc'));
    if (docDir.existsSync()) {
      for (var file in docDir.listSyncSorted().whereType<File>().where(
        (f) => f.publicMarkdownFile,
      )) {
        var name = file.name;
        var title = titleCase(
          p.basenameWithoutExtension(file.path).toLowerCase(),
        );
        var path = '${p.withoutExtension(name)}.html';
        workspace.addChild(
          WorkspaceFile(
            workspace,
            title,
            path,
            createMarkdownGenerator(file),
            FileType.markdown,
          ),
        );
      }
    }

    return workspace;
  }

  WorkspaceFile? getForPath(String path) {
    for (var file in navFiles) {
      if (file.path == path) return file;
    }

    WorkspaceFile? check(WorkspaceDirectory container, String path) {
      if (container.mainFile?.path == path) return container.mainFile;

      for (var child in container.children) {
        if (child is WorkspaceFile) {
          if (child.path == path) return child;
        } else {
          var result = check(child as WorkspaceDirectory, path);
          if (result != null) return result;
        }
      }

      return null;
    }

    return check(this, path);
  }
}
