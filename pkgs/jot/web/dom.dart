// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(devoncarew): Update away from this.
// ignore: deprecated_member_use
import 'dart:html';

T $id<T extends Element>(String id) => document.getElementById(id) as T;

T? $query<T extends Element>(String selector) =>
    document.querySelector(selector) as T?;

ElementList<T> $queryAll<T extends Element>(String selectors) =>
    document.querySelectorAll(selectors);

extension ElementExtension on Element {
  bool parentOf(Element? potentialChild) {
    while (potentialChild != null) {
      potentialChild = potentialChild.parent;
      if (this == potentialChild) return true;
    }
    return false;
  }
}

DivElement div({
  List<String> classes = const [],
  Map<String, String> attributes = const {},
  List<Element> children = const [],
}) {
  return DivElement()
    ..classes.addAll(classes)
    ..attributes.addAll(attributes)
    ..children = children;
}

SpanElement span({
  String? text,
  String? innerHtml,
  List<String> classes = const [],
  Map<String, String> attributes = const {},
}) {
  final element = SpanElement()
    ..classes.addAll(classes)
    ..attributes.addAll(attributes);
  if (text != null) element.text = text;
  if (innerHtml != null) element.innerHtml = innerHtml;
  return element;
}

UListElement ul({
  List<String> classes = const [],
  List<Element> children = const [],
}) {
  return UListElement()
    ..classes.addAll(classes)
    ..children = children;
}

LIElement li({
  List<String> classes = const [],
  Map<String, String> attributes = const {},
  List<Element> children = const [],
}) {
  return LIElement()
    ..classes.addAll(classes)
    ..attributes.addAll(attributes)
    ..children = children;
}

ButtonElement button({String? type, List<String> classes = const []}) {
  final element = ButtonElement()..classes.addAll(classes);
  if (type != null) element.type = type;
  return element;
}

typedef ClickHandler = void Function(MouseEvent event);

AnchorElement a({
  String? text,
  String? href,
  List<String> classes = const [],
  Map<String, String> attributes = const {},
  ClickHandler? onClick,
}) {
  final element = AnchorElement()
    ..classes.addAll(classes)
    ..attributes.addAll(attributes);
  if (text != null) element.text = text;
  if (href != null) element.href = href;
  if (onClick != null) element.onClick.listen(onClick);
  return element;
}
