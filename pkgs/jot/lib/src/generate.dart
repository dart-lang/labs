// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as p;

import '../api.dart';
import '../workspace.dart';
import 'markdown.dart';
import 'render.dart';
import 'utils.dart';

class Generator {
  final Workspace workspace;
  final Directory outDir;
  final Logger logger;
  final Stats? stats;

  Generator({
    required this.workspace,
    required this.outDir,
    required this.logger,
    this.stats,
  });

  Future<void> generate() async {
    // write out the static resources
    await workspace.htmlTemplate.generateStaticResources(outDir, stats: stats);

    // mainFile
    if (workspace.mainFile != null) {
      await _generateFile(workspace.mainFile!);
    }

    // navFiles
    for (var navElement in workspace.navFiles) {
      await _generateFile(navElement, printProgress: false);
    }

    // children
    for (var child in workspace.children) {
      if (child is WorkspaceSeparator) {
        // nothing to generate
      } else if (child is WorkspaceFile) {
        await _generateFile(child, printProgress: !child.isMarkdown);
      } else if (child is WorkspaceDirectory) {
        await _generateContainer(child);
      } else {
        throw StateError('unexpected type: $child');
      }
    }

    // left nav data file
    var navFile = File(p.join(outDir.path, '_resources', 'nav.json'));
    navFile.writeAsStringSync(workspace.generateNavData());
    stats?.genFile(navFile);

    // search index file
    var indexFile = File(p.join(outDir.path, '_resources', 'index.json'));
    indexFile.writeAsStringSync(workspace.api.index.toJson());
    stats?.genFile(indexFile);
  }

  Future<void> _generateContainer(WorkspaceDirectory container) async {
    // mainFile
    // todo: always generate an index file
    if (container.mainFile != null) {
      await _generateFile(container.mainFile!);
    }

    // children
    for (var child in container.children) {
      if (child is WorkspaceSeparator) {
        // nothing to generate
      } else if (child is WorkspaceFile) {
        await _generateFile(child, printProgress: false);
      } else if (child is WorkspaceDirectory) {
        await _generateContainer(child);
      } else {
        throw StateError('unexpected type: $child');
      }
    }
  }

  Future<void> _generateFile(
    WorkspaceFile file, {
    bool printProgress = true,
  }) async {
    var pageContents = await file.generatePageContents();
    var fileContents = await workspace.generateWorkspacePage(
      file,
      pageContents,
    );
    var outFile = File(p.join(outDir.path, file.path));
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(fileContents);

    stats?.genFile(outFile);

    if (printProgress) logger.stdout('  ${p.relative(outFile.path)}');
  }
}

FileContentGenerator libraryGenerator(LibraryItemContainer library) {
  return (Workspace workspace, WorkspaceFile thisFile) async {
    return _LibraryGenerator(
      library: library,
      workspace: workspace,
      thisFile: thisFile,
    ).generate();
  };
}

FileContentGenerator itemsGenerator(Items items) {
  if (items is InterfaceElementItems) {
    return (Workspace workspace, WorkspaceFile thisFile) async {
      return _InterfaceElementGenerator(
        classItems: items,
        workspace: workspace,
        thisFile: thisFile,
      ).generate();
    };
  } else if (items is ExtensionElementItems) {
    return (Workspace workspace, WorkspaceFile thisFile) async {
      return _ExtentionElementGenerator(
        extensionItems: items,
        workspace: workspace,
        thisFile: thisFile,
      ).generate();
    };
  } else {
    throw StateError('unhandled type: $items');
  }
}

class _LibraryGenerator {
  final LibraryItemContainer library;
  final Workspace workspace;
  final WorkspaceFile thisFile;

  _LibraryGenerator({
    required this.library,
    required this.workspace,
    required this.thisFile,
  });

  GenerationResults generate() {
    var api = workspace.api;
    var linkedCodeRenderer = LinkedCodeRenderer(api.resolver, thisFile);

    var buf = StringBuffer();

    if (thisFile.importScript != null) {
      buf.writeln('<h1>${thisFile.name}</h1>');
      buf.writeln(
        '<pre class="declaration">'
        "<code>import '${thisFile.importScript}';</code>"
        '</pre>',
      );
    } else {
      buf.writeln('<h1>${thisFile.name}</h1>');
    }

    if (library.docs != null) {
      // todo: also support compound references - Class.field, Class.method
      buf.writeln(
        convertMarkdown(
          library.docs!,
          linkResolver: library.markdownLinkResolver(api.resolver),
        ),
      );
    }

    var pageItemRenderer = OutlineRenderer();

    if (library.exports.isNotEmpty) {
      buf.writeln('<h2 id="_Exports">Exports</h2>');

      for (var entry in library.exportsByLibrary.entries) {
        var library = entry.key;
        var exports = entry.value;

        buf.writeln('<table>');
        buf.write('<tr><td colspan=2 class="item-title">');
        buf.write('Exports from ${library.urlName}');
        buf.writeln('</td></tr>');

        var itemsByGroup = Items.itemsByGroup(exports);

        for (var entry in itemsByGroup.entries) {
          var groupType = entry.key;
          var items = entry.value;

          buf.write('<tr>');
          buf.write('<td class="item-title">${groupType.title}</td>');
          buf.write('<td class="item-docs">');
          buf.writeln(
            items
                .map((item) {
                  var ref = api.hrefOrSpan(
                    pageItemRenderer.render(item.type, item),
                    item.element,
                    from: thisFile,
                  );
                  return '<code>$ref</code>';
                })
                .join(',\n'),
          );
          buf.write('</td>');
          buf.writeln('</tr>');
        }

        buf.writeln('</table>');
      }
    }

    for (var group in library.groups.values) {
      buf.writeln('<h2 id="${group.anchorId}">${group.name}</h2>');

      if (group.containerType) {
        buf.writeln('<table>');

        for (var item in group.items) {
          buf.write('<tr><td>');
          buf.writeln(
            api.hrefOrSpan(
              pageItemRenderer.render(group.type, item),
              item.element,
              from: thisFile,
            ),
          );
          buf.write('</td>');
          buf.write('<td class="item-docs">');
          if (item.docs != null) {
            buf.writeln(
              convertMarkdown(
                firstSentence(item.docs!),
                linkResolver: item.markdownLinkResolver(api.resolver),
              ),
            );
          }
          buf.write('</td></tr>');
        }

        buf.writeln('</table>');
      } else {
        for (var item in group.items) {
          buf.writeln(
            '<h3 id="${item.anchorId}">${pageItemRenderer.render(group.type, item)}'
            '<span class="symbol-type">${item.element.kind.displayName}</span>'
            '</h3>',
          );
          buf.write(writeAnnotations(item));
          buf.writeln(linkedCodeRenderer.render(group.type, item));
          if (item.docs != null) {
            buf.writeln(
              convertMarkdown(
                item.docs!,
                linkResolver: item.markdownLinkResolver(api.resolver),
              ),
            );
          }
        }
      }
    }

    var outline = Outline();
    var outlineRenderer = OutlineRenderer();

    if (library.exports.isNotEmpty) {
      outline.add(Heading('Exports', id: '_Exports', level: 2));
    }

    for (var group in library.groups.values) {
      outline.add(Heading(group.name, id: group.anchorId, level: 2));

      if (!group.containerType) {
        for (var item in group.items) {
          outline.add(
            Heading(
              outlineRenderer.render(group.type, item),
              id: item.anchorId,
              level: 3,
            ),
          );
        }
      }
    }

    return GenerationResults(buf.toString(), outline);
  }
}

class _InterfaceElementGenerator {
  final InterfaceElementItems classItems;
  final Workspace workspace;
  final WorkspaceFile thisFile;

  _InterfaceElementGenerator({
    required this.classItems,
    required this.workspace,
    required this.thisFile,
  });

  GenerationResults generate() {
    var api = workspace.api;

    var linkedCodeRenderer = LinkedCodeRenderer(api.resolver, thisFile);

    var buf = StringBuffer();
    buf.writeln('<h1>${classItems.name}</h1>');
    buf.write(writeAnnotations(classItems));
    buf.writeln(linkedCodeRenderer.render(classItems.type, classItems));
    writeAncestors(buf);
    _writeChildRelationships(
      buf,
      classItems.relationships,
      thisFile,
      workspace.api,
    );
    if (classItems.docs != null) {
      buf.writeln(
        convertMarkdown(
          classItems.docs!,
          linkResolver: classItems.markdownLinkResolver(api.resolver),
        ),
      );
    }

    var pageItemRenderer = OutlineRenderer();

    for (var group in classItems.groups.values) {
      buf.writeln('<h2 id="${group.anchorId}">${group.name}</h2>');

      if (group.type == GroupType.enumValue) {
        // For enums, add a 'values' table.
        buf.writeln('<table>');

        // todo: also include information about the enum's value

        for (var item in group.items) {
          buf.write('<tr>');
          buf.writeln('<td id="${item.anchorId}">${item.name}</td>');
          buf.write('<td class="item-docs">');
          if (item.docs != null) {
            buf.writeln(
              convertMarkdown(
                item.docs!,
                linkResolver: item.markdownLinkResolver(api.resolver),
              ),
            );
          }
          buf.write('</td></tr>');
        }

        buf.writeln('</table>');
      } else {
        for (var item in group.items) {
          buf.writeln(
            '<h3 id="${item.anchorId}">${pageItemRenderer.render(group.type, item)}'
            '<span class="symbol-type">${item.element.kind.displayName}</span>'
            '</h3>',
          );
          buf.write(writeAnnotations(item));
          buf.writeln(linkedCodeRenderer.render(group.type, item));
          if (item.docs != null) {
            buf.writeln(
              convertMarkdown(
                item.docs!,
                linkResolver: item.markdownLinkResolver(api.resolver),
              ),
            );
          }
        }
      }
    }

    var outline = Outline();
    var outlineRenderer = OutlineRenderer();

    for (var group in classItems.groups.values) {
      outline.add(Heading(group.name, id: group.anchorId, level: 2));

      if (group.type != GroupType.enumValue) {
        for (var item in group.items) {
          outline.add(
            Heading(
              outlineRenderer.render(group.type, item),
              id: item.anchorId,
              level: 3,
            ),
          );
        }
      }
    }

    return GenerationResults(buf.toString(), outline);
  }

  void writeAncestors(StringBuffer out) {
    var buf = StringBuffer();
    final api = workspace.api;

    var element = classItems.element;
    var superElement = element.supertype?.element;
    if (superElement != null) {
      buf.writeln('<tr><td class="item-title">Extends</td>');
      buf.write('<td class="item-docs">');
      var ref = api.hrefOrSpan(superElement.name, superElement, from: thisFile);
      buf.write('<code>$ref</code></td></tr>');
    }

    if (element.interfaces.isNotEmpty) {
      buf.writeln('<tr><td class="item-title">Implements</td>');
      buf.write('<td class="item-docs">');
      buf.write(
        element.interfaces
            .map(
              (i) => api.hrefOrSpan(i.element.name, i.element, from: thisFile),
            )
            .map((s) => '<code>$s</code>')
            .join(', '),
      );
      buf.write('</td></tr>');
    }

    if (element.mixins.isNotEmpty) {
      buf.writeln('<tr><td class="item-title">Mixins</td>');
      buf.write('<td class="item-docs">');
      buf.write(
        element.mixins
            .map(
              (m) => api.hrefOrSpan(m.element.name, m.element, from: thisFile),
            )
            .map((s) => '<code>$s</code>')
            .join(', '),
      );
      buf.write('</td></tr>');
    }

    if (buf.isNotEmpty) {
      out.writeln('<table>');
      out.write(buf.toString());
      out.writeln('</table>');
    }
  }
}

class _ExtentionElementGenerator {
  final ExtensionElementItems extensionItems;
  final Workspace workspace;
  final WorkspaceFile thisFile;

  _ExtentionElementGenerator({
    required this.extensionItems,
    required this.workspace,
    required this.thisFile,
  });

  GenerationResults generate() {
    var api = workspace.api;

    var linkedCodeRenderer = LinkedCodeRenderer(api.resolver, thisFile);

    var buf = StringBuffer();
    buf.writeln('<h1>${extensionItems.name}</h1>');
    buf.write(writeAnnotations(extensionItems));
    buf.writeln(linkedCodeRenderer.render(extensionItems.type, extensionItems));
    writeAncestors(buf);
    _writeChildRelationships(
      buf,
      extensionItems.relationships,
      thisFile,
      workspace.api,
    );
    if (extensionItems.docs != null) {
      buf.writeln(
        convertMarkdown(
          extensionItems.docs!,
          linkResolver: extensionItems.markdownLinkResolver(api.resolver),
        ),
      );
    }

    var pageItemRenderer = OutlineRenderer();

    for (var group in extensionItems.groups.values) {
      buf.writeln('<h2 id="${group.anchorId}">${group.name}</h2>');

      for (var item in group.items) {
        buf.writeln(
          '<h3 id="${item.anchorId}">${pageItemRenderer.render(group.type, item)}'
          '<span class="symbol-type">${item.element.kind.displayName}</span>'
          '</h3>',
        );
        buf.write(writeAnnotations(item));
        buf.writeln(linkedCodeRenderer.render(group.type, item));
        if (item.docs != null) {
          buf.writeln(
            convertMarkdown(
              item.docs!,
              linkResolver: item.markdownLinkResolver(api.resolver),
            ),
          );
        }
      }
    }

    var outline = Outline();
    var outlineRenderer = OutlineRenderer();

    for (var group in extensionItems.groups.values) {
      outline.add(Heading(group.name, id: group.anchorId, level: 2));

      for (var item in group.items) {
        outline.add(
          Heading(
            outlineRenderer.render(group.type, item),
            id: item.anchorId,
            level: 3,
          ),
        );
      }
    }

    return GenerationResults(buf.toString(), outline);
  }

  void writeAncestors(StringBuffer out) {
    var buf = StringBuffer();
    final api = workspace.api;

    var element = extensionItems.asExtension;
    var extendedElement = element.extendedType.element;
    if (extendedElement != null && extendedElement.name != null) {
      buf.writeln('<tr><td class="item-title">Extension on</td>');
      buf.write('<td class="item-docs">');
      var ref = api.hrefOrSpan(
        extendedElement.name!,
        extendedElement,
        from: thisFile,
      );
      buf.write('<code>$ref</code></td></tr>');
    }

    if (buf.isNotEmpty) {
      out.writeln('<table>');
      out.write(buf.toString());
      out.writeln('</table>');
    }
  }
}

void _writeChildRelationships(
  StringBuffer buf,
  RelationshipMap relationships,
  WorkspaceFile thisFile,
  Api api,
) {
  if (relationships.isEmpty) return;

  buf.writeln('<table>');

  for (var kind in relationships.keys) {
    buf.write('<tr>');
    buf.write('<td class="item-title">${kind.title}</td>');

    buf.write('<td class="item-docs">');
    var items = relationships[kind]!;
    items.sort((a, b) => adjustedLexicalCompare(a.name, b.name));
    buf.write(
      items
          .map((item) {
            var ref = api.hrefOrSpan(item.name, item.element, from: thisFile);
            return '<code>$ref</code>';
          })
          .join(', '),
    );
    buf.writeln('</td></tr>');
  }

  buf.writeln('</table>');
}
