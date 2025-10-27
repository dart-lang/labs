// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_style/dart_style.dart';

class DartFormat {
  // TODO: if there are any formatting failures, return the input string
  static String asFunction(String str) {
    return _dartFormat(str, '{}');
  }

  static String asConstructor(
    String str, {
    required String className,
    bool isConst = false,
  }) {
    return _dartFormat(
      str,
      isConst ? ';' : '{}',
      prefix: 'class $className {',
      suffix: '}',
      trimIndent: true,
    );
  }

  static String asMethod(String str) {
    return _dartFormat(
      str,
      '{}',
      prefix: 'class Foo {',
      suffix: '}',
      trimIndent: true,
    );
  }

  static String asField(String str) {
    return _dartFormat(
      str,
      ';',
      prefix: 'class Foo {',
      suffix: '}',
      trimIndent: true,
    );
  }

  static String asTypeAlias(String str) {
    return _dartFormat(str, ';');
  }

  static String asClass(String str) {
    return _dartFormat(str, ' {}');
  }

  static String asEnum(String str) {
    return _dartFormat(str, ' { foo }');
  }

  static String _dartFormat(
    String fragment,
    String formattingSuffix, {
    String? prefix,
    String? suffix,
    bool trimIndent = false,
  }) {
    var source =
        '''
${prefix ?? ''}
// cut 1
$fragment$formattingSuffix
// cut 2
${suffix ?? ''}
''';
    final formatter = DartFormatter();
    source = formatter.format(source);
    source = source.substring(
      source.indexOf('// cut 1') + '// cut 1'.length,
      source.indexOf('// cut 2'),
    );
    source = source.trim();
    if (source.endsWith(formattingSuffix)) {
      source = source.substring(0, source.length - formattingSuffix.length);
    }

    if (trimIndent) {
      source = source
          .split('\n')
          .map((line) => line.startsWith('  ') ? line.substring(2) : line)
          .join('\n');
    }

    source = source.trimRight();

    return source;
  }
}
