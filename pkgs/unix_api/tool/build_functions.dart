// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

final ffigenTypes = <Pattern>[
  'void',
  'int',
  'unsigned',
  'char *',
  'const char *',
  'long',
  RegExp(r'int\[\d*\]'),
];

const d = <String, String>{
  'pid_t': 'long long', // POSIX: must be signed integer type
};

const _cSourceTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

#include <assert.h>

#include "constants.g.h"

''';

const _cHeaderTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_functions.dart`.

#include <stdint.h>

// A sentinal indicating that a constant is not defined on the current platform.
//
// It is a random sequence of 64 bits and used by `constants.g.dart` to
// determine whether a value returned by `libc_shim_get_(constant)` is the
// actual platform constant or is undefined.
#define libc_shim_UNDEFINED 5635263260456932693
''';

const _dartTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_constants.dart`.

// ignore_for_file: non_constant_identifier_names

import 'constant_bindings.g.dart';
''';

void addFunctionToCSource(
  String functionName,
  String returnType,
  List<String> args,
  StringBuffer b,
) {
  String letters = 'abcdefghj';

  final parameters = <String>[];
  for (var i = 0; i < args.length; ++i) {
    parameters.add('${args[i]} ${letters[i]}');
  }
  b.write('''
$returnType libc_shim_get_$functionName(${parameters.join(", ")}) {
  return $functionName(${[for (var i = 0; i < args.length; ++i) letters[i]].join(', ')});
}
''');
}

void addFunctionToCHeader(
  String functionName,
  String returnType,
  List<String> args,
  StringBuffer b,
) {
  b.write('''
__attribute__((visibility("default"))) __attribute__((used))
$returnType libc_shim_get_$functionName(${args.join(", ")});
''');
}

void addConstantToDart(String constant, StringBuffer b) {
  b.writeln('''
int get $constant {
  final v = get_$constant();
  if (v == libc_shim_UNDEFINED) {
    throw UnsupportedError('$constant');
  } else {
    return v;
  }
}
''');
}

RegExp exp = RegExp(
  r'^\s*(?<return>.+?)\s*'
  r'(?<name>\w+)'
  r'\((?<args>[^)]*)\)',
);

class CFunction {
  final String name;
  final String returnType;
  final List<String> argumentTypes;

  const CFunction(this.name, this.returnType, this.argumentTypes);
}

bool acceptableType(String type) {
  return ffigenTypes.any((x) => x.matchAsPrefix(type) != null);
}

/// Generates Dart and C source from "constants.json"
///
/// Generates the following files based on "constants.json":
/// o lib/src/constants.g.dart
/// o src/constants.g.c
/// o src/constants.g.h
///
/// After `build_constants.dart` completes, run:
/// `dart run ffigen --config constants-ffigen.yaml`
void main() {
  final headerToConstants =
      (json.decode(File('functions.json').readAsStringSync()) as Map)
          .cast<String, Object>();

  final cSourceBuffer = StringBuffer(_cSourceTemplate);
  final cHeaderBuffer = StringBuffer(_cHeaderTemplate);
  final dartBuffer = StringBuffer(_dartTemplate);

  final headers = headerToConstants.keys.toList()..sort();
  for (final header in headers) {
    cSourceBuffer.writeln('#include $header');
  }

  for (final header in headers) {
    final functions = (headerToConstants[header]! as List).cast<Map>();
    for (final function in functions) {
      print(function['prototype']);
      final match = exp.firstMatch(function['prototype'])!;

      final returnType = match.namedGroup('return')!;
      final functionName = match.namedGroup('name')!;
      final args = match.namedGroup('args')!;

      if (!acceptableType(returnType)) {
        throw Exception('invalid return type $returnType for $functionName');
      }

      final typeList = args.split(RegExp(r'\s*,\s*'));

      for (var type in typeList) {
        if (!acceptableType(type)) {
          throw Exception('invalid argument type $type for $functionName');
        }
      }

      //      addFunctionToCSource()
    }
  }
  //  File('lib/src/constants.g.dart').writeAsStringSync(dartBuffer.toString());
  //  File('src/constants.g.c').writeAsStringSync(cSourceBuffer.toString());
  //  File('src/constants.g.h').writeAsStringSync(cHeaderBuffer.toString());
}
