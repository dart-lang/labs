// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'cfunction.dart';

const _cSourceTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

#include <assert.h>
#include <errno.h>

#include "functions.g.h"

''';

const _cHeaderTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

''';

/// Parses a C function declaration like.
///
/// `"char * crypt(const char *, const char *)"`
/// =>
/// return = "char *"
/// name = "crypt"
/// args = ["const char *", "const char *"]
RegExp _cDeclaration = RegExp(
  r'^\s*(?<return>.+?)\s*'
  r'(?<name>\w+)'
  r'\((?<args>[^)]*)\)',
);

/// Generates Dart and C source from "functions.json"
///
/// Generates the following files based on "functions.json":
/// o src/functions.g.c
/// o src/functions.g.h
///
/// After `build_functions.dart` completes, run:
/// `dart run ffigen --config ffigen.yaml`
void main() {
  final headerToConstants =
      (json.decode(File('functions.json').readAsStringSync()) as Map)
          .cast<String, Object>();

  final cSourceBuffer = StringBuffer(_cSourceTemplate);
  final cHeaderBuffer = StringBuffer(_cHeaderTemplate);

  final headers = headerToConstants.keys.toList()..sort();
  for (final header in headers) {
    cSourceBuffer.writeln('#include $header');
  }

  for (final header in headers) {
    final functions = (headerToConstants[header]! as List).cast<Map>();
    for (final function in functions) {
      final match = _cDeclaration.firstMatch(function['prototype'])!;

      final returnType = match.namedGroup('return')!;
      final functionName = match.namedGroup('name')!;
      final args = match.namedGroup('args')!;
      final typeList = args.split(RegExp(r'\s*,\s*'));

      final func = CFunction(
        functionName,
        returnType,
        typeList,
        function['comment'],
        function['url'],
        availableAndroid: function['available_android'] ?? true,
        availableIOS: function['available_ios'] ?? true,
        unavailableReturn: function['error_value'],
      );

      cHeaderBuffer.writeln(func.dartDeclaration('libc_shim_'));
      cHeaderBuffer.writeln();
      cSourceBuffer.writeln(func.trampoline('libc_shim_'));
      cSourceBuffer.writeln();
    }
  }
  File('src/functions.g.c').writeAsStringSync(cSourceBuffer.toString());
  File('src/functions.g.h').writeAsStringSync(cHeaderBuffer.toString());
}
