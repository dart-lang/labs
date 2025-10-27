// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
// TODO(devoncarew): Update away from this.
// ignore: deprecated_member_use
import 'dart:html';

import 'dom.dart';
import 'interop.dart';
import 'utils.dart';

typedef UrlHandler = void Function(String url);

class SearchUI {
  final String urlBase;
  final UrlHandler urlHandler;

  late final InputElement searchBox;
  late final SearchResultsUI searchResultsUI;

  late final Index index;

  SearchUI(this.urlBase, this.urlHandler) {
    index = Index(urlBase);

    searchBox = $id('search') as InputElement;
    searchResultsUI = SearchResultsUI(
      urlHandler,
      $query('div.search-glass-pane')!,
      $query('div.search-area')!,
    );

    document.onKeyPress.listen((event) {
      if (event.key == '/') {
        event.preventDefault();

        _activate();
      }
    });

    searchBox.onKeyDown.listen((event) {
      if (event.key == 'Escape') {
        _deactivate();
      } else if (event.key == 'Enter') {
        event.preventDefault();
        _selectCurrent();
      } else if (event.key == 'ArrowDown') {
        searchResultsUI.selectDown();
      } else if (event.key == 'ArrowUp') {
        searchResultsUI.selectUp();
      }
    });

    searchBox.onInput.listen((event) {
      _handleInputChanged(searchBox.value ?? '');
    });

    searchBox.onClick.listen((event) {
      _activate();
    });
  }

  void _activate() {
    searchBox.focus();

    var text = (searchBox.value ?? '').trim();
    if (text.isNotEmpty) {
      searchResultsUI.show();
    }
  }

  void _selectCurrent() {
    searchResultsUI.selectCurrent();
  }

  void _deactivate() {
    searchBox.blur();
    searchResultsUI.hide();
  }

  void _handleInputChanged(String text) {
    text = text.trim();

    if (text.isEmpty) {
      searchResultsUI.hide();
    } else {
      searchResultsUI.show();

      // ignore: unnecessary_lambdas
      index.search(text).then((results) {
        // Show the search results in the UI.
        searchResultsUI.displayResults(results);
      });
    }
  }
}

class SearchResultsUI {
  static const Duration _delay = Duration(milliseconds: 200);

  final UrlHandler urlHandler;

  final Element glassPane;
  final Element searchArea;

  List<IndexMember> items = [];
  final Map<IndexMember, LIElement> itemToElement = {};
  IndexMember? selected;

  SearchResultsUI(this.urlHandler, this.glassPane, this.searchArea) {
    glassPane.onMouseDown.listen((_) {
      hide();
    });
    searchArea.onMouseDown.listen((event) {
      event.stopPropagation();
    });
  }

  bool get showing => glassPane.style.display != 'none';

  void show() {
    if (!showing) {
      glassPane.style.display = 'block';
      Timer.run(() => glassPane.style.opacity = '1.0');
    }
  }

  void selectCurrent() {
    if (selected != null) {
      urlHandler(selected!.url);
    }

    hide();
  }

  void selectUp() {
    if (selected == null) return;
    var index = items.indexOf(selected!);
    if (index == 0) return;

    var li = itemToElement[selected]!;
    li.classes.remove('selected');
    selected = items[index - 1];
    li = itemToElement[selected]!;
    li.classes.add('selected');

    li.scrollIntoViewIfNeeded();
  }

  void selectDown() {
    if (selected == null) return;
    var index = items.indexOf(selected!);
    if (index + 1 >= items.length) return;

    var li = itemToElement[selected]!;
    li.classes.remove('selected');
    selected = items[index + 1];
    li = itemToElement[selected]!;
    li.classes.add('selected');

    li.scrollIntoViewIfNeeded();
  }

  void displayResults(SearchResults results) {
    const maxLimit = 100;

    var items = results.items.map((result) => result.item).toList();
    var total = items.length;

    if (items.length > maxLimit) {
      items = items.take(maxLimit).toList();
    }

    this.items = items;
    itemToElement.clear();
    selected = null;

    var ul = searchArea.querySelector('ul')!;
    ul.children.clear();
    ul.children.addAll(
      items.map((item) {
        var li = _renderItem(results.pattern, item);
        itemToElement[item] = li;
        return li;
      }),
    );
    selected = items.isEmpty ? null : items.first;
    itemToElement[selected]?.classes.add('selected');
    ul.scrollTop = 0;

    var footer = searchArea.querySelector('div.search-footer')!;

    if (total != items.length) {
      footer.text =
          'showing ${items.length} of $total ${plural('item', total)}';
    } else {
      footer.text = '${items.length} ${plural('item', total)}';
    }
  }

  LIElement _renderItem(String pattern, IndexMember item) {
    return li(
        classes: ['margin--sm', 'padding--sm'],
        children: [
          div(
            children: [
              ..._renderMatchText(item.display, item.name, pattern),
              span(text: item.importReference(true), classes: ['location']),
              span(text: item.type, classes: ['type', 'badge']),
            ],
          ),
          div(
            classes: ['docs'],
            children: [
              if (item.docs == null) span(innerHtml: '&nbsp;'),
              if (item.docs != null) span(text: item.docs),
            ],
          ),
        ],
      )
      ..onMouseDown.listen((event) {
        event.stopPropagation();
        urlHandler(item.url);
        hide();
      });
  }

  void hide() {
    if (showing) {
      glassPane.style.opacity = '0.0';
      Timer(_delay, () => glassPane.style.display = 'none');
    }
  }
}

List<Element> _renderMatchText(String display, String name, String pattern) {
  var startsAt = 0;
  var nameIndex = display.indexOf('.$name');
  if (nameIndex != -1) {
    startsAt = nameIndex;
  }

  var matchAt = display.indexOf(pattern, startsAt);
  if (matchAt == -1) {
    matchAt = display.toLowerCase().indexOf(pattern.toLowerCase(), startsAt);
  }
  if (matchAt == -1) {
    matchAt = display.toLowerCase().indexOf(pattern.toLowerCase());
  }

  if (matchAt == -1) {
    return [span(text: display)];
  } else {
    return [
      span(text: display.substring(0, matchAt)),
      span(
        text: display.substring(matchAt, matchAt + pattern.length),
        classes: ['match'],
      ),
      span(text: display.substring(matchAt + pattern.length)),
    ];
  }
}

class Index {
  late final List<IndexMember> members;

  final Completer _completer = Completer();

  Index(String urlBase) {
    _init(urlBase)
        .then((result) {
          members = result;
          _completer.complete();
        })
        .catchError((dynamic error) {
          members = [];
          print('error reading index: $error');
          _completer.complete();
        });
  }

  Future<void> ready() => _completer.future;

  Future<List<IndexMember>> _init(String urlBase) async {
    var response =
        (await window.fetch('${urlBase}_resources/index.json'))
            as FetchResponse;
    var code = response.status;
    if (code == 404) {
      print('error response: $response');
      return [];
    }

    var text = await promiseToFuture<String>(response.text());
    var jsonIndex = (jsonDecode(text) as List).cast<JsonType>();
    return jsonIndex.map(IndexMember._parse).toList();
  }

  Future<SearchResults> search(String pattern) async {
    await ready();

    var lower = pattern.toLowerCase();

    var potential = <IndexMember>[];
    for (var member in members) {
      _gatherPotentialMatches(lower, member, potential);
    }

    return SearchResults(pattern, potential);
  }

  static void _gatherPotentialMatches(
    String pattern,
    IndexMember member,
    List<IndexMember> matches,
  ) {
    if (member.ref != null) {
      if (member.name.toLowerCase().contains(pattern) ||
          member.display.toLowerCase().contains(pattern)) {
        matches.add(member);
      }
    }

    if (member.children.isNotEmpty) {
      for (var child in member.children) {
        _gatherPotentialMatches(pattern, child, matches);
      }
    }
  }
}

// [
//   {"t":"package","n":"package:jot","c":[
//     {"t":"library","n":"jot.dart","d":
//         "To create a new DocWorkspace, see ...","ref":"jot.html","c":[
//       {"t":"class","n":"Jot","ref":"jot/Jot.html","c":[
//         {"t":"constructor","n":"Jot"},
//         {"t":"field","n":"inDir"},
//         {"t":"field","n":"outDir"},
//         {"t":"method","n":"generate"},
//         {"t":"method","n":"serve"}
//       ]}
//     ]},
// ...

abstract class IndexMember {
  final String name;
  final String type;
  final String? docs;

  IndexMember? parent;

  String? get ref;
  String? get id;
  List<IndexMember> get children;

  IndexMember(this.name, this.type, this.docs);

  String get display {
    if (type == 'class') {
      return '$name { … }';
    } else if (type == 'function' || type == 'constructor') {
      return '$name()';
    } else if (type == 'method') {
      return '$_maybeParent$name()';
    } else if (type == 'field' || type == 'accessor') {
      return '$_maybeParent$name';
    } else {
      return name;
    }
  }

  String? get packageName {
    var p = parent;
    while (p != null) {
      if (p.type == 'package') return p.name;
      p = p.parent;
    }
    return null;
  }

  String get url => id != null ? '$ref#$id' : ref!;

  String? importReference(bool includePackageName) {
    IndexMember? p = this;
    while (p != null) {
      if (p.type == 'library') {
        var libraryName = p.name;
        if (!includePackageName) return libraryName;
        var package = p.packageName;
        return package == null ? libraryName : '$package/$libraryName';
      }
      p = p.parent;
    }
    return null;
  }

  String get _maybeParent {
    if (parent == null) return '';
    if (parent!.type == 'library') return '';

    return '${parent!.name}.';
  }

  factory IndexMember._parse(JsonType json) {
    var name = json['n'] as String;
    var type = json['t'] as String;
    var docs = json['d'] as String?;

    var ref = json['ref'] as String?;
    var children = json['c'] as List?;

    if (ref != null || children != null) {
      var item = IndexParent(
        name,
        type,
        docs,
        ref,
        children == null
            ? const []
            : children.map((c) => IndexMember._parse(c as JsonType)).toList(),
      );
      for (var child in item.children) {
        child.parent = item;
      }
      return item;
    } else {
      return IndexLeaf(name, type, docs, json['#'] as String?);
    }
  }

  static const Set<String> importantPackages = {'flutter'};

  static const Set<String> discouragedPackages = {
    'dart:cli',
    'dart:html',
    'dart:indexed_db',
    'dart:mirrors',
    'dart:svg',
    'dart:web_audio',
    'dart:web_gl',
  };

  int calcRank(String pattern, String patternLower) {
    var rank = 100;

    var name = this.name;

    // grouping:
    if (name == pattern) {
      // - exact, same length
      rank += 300;
    } else if (name.startsWith(pattern)) {
      // - exact (case is the same)
      rank += 200;
    } else if (name.toLowerCase().startsWith(patternLower)) {
      // - same (same case-insensitive)
      rank += 100;
    } else if (display.toLowerCase().startsWith(patternLower)) {
      rank += 50;
    }

    // sorting:

    // - Class, extension, enums
    if (type == 'class' || type == 'extension' || type == 'enum') {
      rank += 10;
    }

    var package = packageName;
    if (importantPackages.contains(package)) {
      // - from an important package
      rank += 5;
    } else if (discouragedPackages.contains(package)) {
      // - from a deprecated package
      rank -= 5;
    }

    return rank;
  }

  @override
  String toString() => '$type $name';
}

class IndexParent extends IndexMember {
  @override
  final String? ref;
  @override
  final List<IndexMember> children;

  IndexParent(super.name, super.type, super.docs, this.ref, this.children);

  @override
  String? get id => null;
}

class IndexLeaf extends IndexMember {
  final String? _id;

  IndexLeaf(super.name, super.type, super.docs, this._id);

  @override
  String? get id => _id ?? (ref != null ? name : null);

  @override
  String? get ref => parent?.ref;

  @override
  List<IndexMember> get children => const [];
}

class SearchResults {
  final String pattern;
  late final List<SearchResult> items;

  SearchResults(this.pattern, List<IndexMember> rawItems) {
    final patternLower = pattern.toLowerCase();

    items = rawItems.map((item) {
      return SearchResult(item.calcRank(pattern, patternLower), item);
    }).toList()..sort();
  }
}

class SearchResult implements Comparable<SearchResult> {
  final int rank;
  final IndexMember item;

  SearchResult(this.rank, this.item);

  @override
  int compareTo(SearchResult other) {
    var diff = other.rank - rank;
    if (diff != 0) return diff;

    diff = item.name.compareTo(other.item.name);
    if (diff != 0) return diff;

    diff = item.display.length - other.item.display.length;
    if (diff != 0) return diff;

    return item.display.compareTo(other.item.display);
  }

  @override
  String toString() => '[$rank $item]';
}
