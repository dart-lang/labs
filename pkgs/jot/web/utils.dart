// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef JsonType = Map<String, dynamic>;

String plural(String word, int count) => count == 1 ? word : '${word}s';

class Path {
  String parent(String path) {
    if (path.contains('/')) {
      return path.substring(0, path.lastIndexOf('/'));
    } else {
      return '';
    }
  }

  String file(String path) {
    if (path.contains('/')) {
      return path.substring(path.lastIndexOf('/') + 1);
    } else {
      return path;
    }
  }

  String join(String a, String b) {
    if (a.endsWith('/')) {
      return '$a$b';
    } else if (a.isNotEmpty) {
      return '$a/$b';
    } else {
      return b;
    }
  }

  String normalize(String path) {
    if (!path.contains('..')) return path;

    var tokens = path.split('/');

    for (var i = 0; i < tokens.length;) {
      var token = tokens[i];
      if (token == '..' && i > 0 && tokens[i - 1] != '..') {
        tokens.removeAt(i);
        tokens.removeAt(i - 1);
        i--;
      } else {
        i++;
      }
    }

    return tokens.join('/');
  }

  String relative(String path, {required String from}) {
    if (from.isEmpty) return path;

    var paths = path.split('/');
    var froms = from.split('/');

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
