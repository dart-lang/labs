// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

const _cSourceTemplate = '''
#include "constants.g.h"

''';

const _cHeaderTemplate = '''
#include <stdint.h>

// A sentinal indicating that a constant is not defined on the current platform.
#define libc_shim_UNDEFINED 9223372036854775807
''';

const _dartTemplate = '''
// ignore_for_file: non_constant_identifier_names

import 'constant_bindings.dart';
''';

void addConstantToCSource(String constant, StringBuffer b) {
  b.write('''
int64_t libc_shim_get_$constant(void) {
#ifdef $constant
  return $constant;
#endif
  return libc_shim_UNDEFINED;
}
''');
}

void addConstantToCHeader(String constant, StringBuffer b) {
  b.write('''
__attribute__((visibility("default"))) __attribute__((used))
int64_t libc_shim_get_$constant(void);
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
      (json.decode(File('constants.json').readAsStringSync()) as Map)
          .cast<String, Object>();

  final cSourceBuffer = StringBuffer(_cSourceTemplate);
  final cHeaderBuffer = StringBuffer(_cHeaderTemplate);
  final dartBuffer = StringBuffer(_dartTemplate);

  final headers = headerToConstants.keys.toList()..sort();
  for (final header in headers) {
    cSourceBuffer.writeln('#include $header');
  }

  for (final header in headers) {
    final constants = (headerToConstants[header]! as List).cast<String>();
    for (final constant in constants) {
      addConstantToCHeader(constant, cHeaderBuffer);
      addConstantToCSource(constant, cSourceBuffer);
      addConstantToDart(constant, dartBuffer);
    }
  }
  File('lib/src/constants.g.dart').writeAsStringSync(dartBuffer.toString());
  File('src/constants.g.c').writeAsStringSync(cSourceBuffer.toString());
  File('src/constants.g.h').writeAsStringSync(cHeaderBuffer.toString());
}
