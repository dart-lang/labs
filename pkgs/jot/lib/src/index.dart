// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../api.dart';
import 'markdown.dart';

// build the index
String? docSummary(Item item) {
  // get docs
  var docs = item.docs;
  if (docs == null) return null;

  // first sentence
  docs = firstSentence(docs);

  // convert to plaintext; resolve refs to plain text
  docs = markdownToText(docs);

  // consolidate ws
  docs = docs.replaceAll('\n', ' ');

  // first 80 chars
  const limit = 80;
  return docs.length > limit
      ? '${docs.substring(0, limit - 1).trimRight()}…'
      : docs;
}

// "t":"$class"
// "t":"$enum"
// "t":"$extension"
// "t":"accessor"
// "t":"constructor"
// "t":"enumValue"
// "t":"field"
// "t":"function"
// "t":"library"
// "t":"method"
// "t":"package"
// "t":"typeAlias"

class Index extends IndexMember {
  Index() : super('', 'index');

  String toJson() {
    var buf = StringBuffer('[\n');
    children.sort();
    for (var child in children) {
      child._writeTo(buf, appendComma: child != children.last);
    }
    buf.writeln(']');
    return buf.toString();
  }
}

class IndexMember implements Comparable<IndexMember> {
  final String name;
  final String type;
  final String? ref;
  final String? id;
  final String? docs;

  final List<IndexMember> children = [];

  IndexMember(this.name, this.type, {this.ref, this.id, this.docs});

  IndexMember add(
    String name,
    String type, {
    String? ref,
    String? id,
    String? docs,
  }) {
    var child = IndexMember(name, type, ref: ref, id: id, docs: docs);
    children.add(child);
    return child;
  }

  void _writeTo(StringBuffer buf, {bool appendComma = false}) {
    // One optimization here would be to
    //  1) use a single char for the type field
    //  2) prepend the type to the name field
    buf.write('{"t":"$type","n":"$name"');
    if (docs != null) buf.write(',"d":${jsonEncode(docs)}');
    if (ref != null) buf.write(',"ref":"$ref"');
    // Only write an explicit anchor value if it is different from the item
    // name.
    if (id != null && id != name) buf.write(',"#":"$id"');
    if (children.isNotEmpty) {
      buf.writeln(',"c":[');
      children.sort();
      for (var child in children) {
        child._writeTo(buf, appendComma: child != children.last);
      }
      buf.writeln(']}${appendComma ? ',' : ''}');
    } else {
      buf.writeln('}${appendComma ? ',' : ''}');
    }
  }

  @override
  int compareTo(IndexMember other) {
    var a = (children.isEmpty ? '_' : '') + type;
    var b = (other.children.isEmpty ? '_' : '') + other.type;
    return a.compareTo(b);
  }
}
