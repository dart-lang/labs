// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:markdown/markdown.dart';

import 'utils.dart';

// todo: sanitize html (see lib/src/render/documentation_renderer.dart from
//       dartdoc)

// todo: link resolver

// todo: markdown files can create id attributes

// todo: ensure that element docs cannot create id attributes

class MarkdownResults {
  final String html;
  final Outline outline;

  MarkdownResults(this.html, this.outline);
}

typedef MarkdownLinkResolver = String? Function(String reference);

String convertMarkdown(String markdown, {MarkdownLinkResolver? linkResolver}) {
  return markdownToHtml(
    markdown,
    extensionSet: ExtensionSet.gitHubWeb,
    enableTagfilter: true,
    linkResolver: (String name, [String? title]) {
      String? href;

      if (linkResolver != null) {
        href = linkResolver(name);
      }

      if (href == null) {
        return Element.text('span', name)..attributes['class'] = 'code';
      } else {
        return Element.text('a', name)
          ..attributes['href'] = href
          ..attributes['class'] = 'code';
      }
    },
  );
}

String firstSentence(String markdown) {
  return markdown
      .split('\n')
      .takeWhile((line) => line.trim().isNotEmpty && !line.startsWith('```'))
      .join('\n');
}

String markdownToText(String markdown) {
  final visitor = _TextVisitor();
  final document = Document(
    extensionSet: ExtensionSet.gitHubWeb,
    encodeHtml: false,
    linkResolver: (name, [text]) => Element.text('span', name),
  );
  for (final node in document.parse(markdown)) {
    node.accept(visitor);
  }
  return visitor.toString();
}

MarkdownResults convertMarkdownWithOutline(String markdown) {
  final document = Document(extensionSet: ExtensionSet.gitHubWeb);

  final nodes = document.parse(markdown);

  var contents = '${renderToHtml(nodes, enableTagfilter: true)}\n';
  var elements = nodes.whereType<Element>().where(
    (element) => element.tag == 'h2' || element.tag == 'h3',
  );

  return MarkdownResults(contents, _toOutline(elements));
}

Outline _toOutline(Iterable<Element> elements) {
  var outline = Outline();
  for (var element in elements) {
    var level = int.parse(element.tag.substring(1));
    outline.add(
      Heading(element.textContent, level: level, id: element.generatedId),
    );
  }
  return outline;
}

class _TextVisitor implements NodeVisitor {
  final StringBuffer buf = StringBuffer();

  @override
  String toString() => buf.toString();

  @override
  bool visitElementBefore(Element element) {
    return true;
  }

  @override
  void visitText(Text text) {
    buf.write(text.text);
  }

  @override
  void visitElementAfter(Element element) {}
}
