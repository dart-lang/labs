// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:jot/src/index.dart';
import 'package:test/test.dart';

void main() {
  test('empty', () {
    var index = Index();

    var text = index.toJson();
    var json = jsonDecode(text);
    expect(json, isEmpty);
  });

  test('ref', () {
    var index = Index();
    var package = index.add('package:foo', 'package');
    package.add('main.dart', 'library', ref: 'main.html');

    var text = index.toJson();
    var json = jsonDecode(text);
    expect(json, isNotEmpty);
    var packageRef = _Item((json as List)[0] as _JsonType);
    var libraryRef = packageRef.children[0];
    expect(libraryRef.ref, isNotEmpty);
  });

  test('id', () {
    var index = Index();
    var package = index.add('package:foo', 'package');
    var library = package.add('main.dart', 'library', ref: 'main.html');
    library.add('foo', 'field', id: 'foo');

    var text = index.toJson();
    var json = jsonDecode(text);
    expect(json, isNotEmpty);
    var packageRef = _Item((json as List)[0] as _JsonType);
    var libraryRef = packageRef.children[0];
    var fieldRef = libraryRef.children[0];
    expect(fieldRef.id, isNotEmpty);
  });

  test('simple', () {
    var index = Index();
    var package = index.add('package:foo', 'package');
    var library = package.add('main.dart', 'library', ref: 'main.html');
    library.add('foo', 'field', id: 'foo');
    library.add('bar', 'method', id: 'bar');

    var text = index.toJson();
    var json = jsonDecode(text);
    expect(json, isNotEmpty);
  });
}

typedef _JsonType = Map<String, dynamic>;

class _Item {
  final _JsonType json;

  _Item(this.json);

  List<_Item> get children {
    if (!json.containsKey('c')) return [];
    return (json['c'] as List).map((json) => _Item(json as _JsonType)).toList();
  }

  String get name => json['n'] as String;
  String get type => json['t'] as String;
  String? get ref => json['ref'] as String?;
  String? get id =>
      (json['#'] as String?) ?? (!json.containsKey('c') ? name : null);
}
