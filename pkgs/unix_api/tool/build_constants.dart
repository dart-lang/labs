// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:yaml/yaml.dart';

const _cSourceTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_constants.dart`.

#include <assert.h>

#include "constants.g.h"

''';

const _cHeaderTemplate = '''
// AUTO GENERATED FILE, DO NOT EDIT.
// Regenerate with `dart run tool/build_constants.dart`.

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

void addConstantToCSource(String constant, StringBuffer b) {
  b.write('''
int64_t libc_shim_get_$constant(void) {
#ifdef $constant
  assert($constant != libc_shim_UNDEFINED);
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

/// Generates Dart and C source from "constants.yaml"
///
/// Generates the following files based on "constants.yaml":
/// o lib/src/constants.g.dart
/// o src/constants.g.c
/// o src/constants.g.h
///
/// After `build_constants.dart` completes, run:
/// `dart run ffigen --config constants-ffigen.yaml`
void main() {
  final headerToConstants =
      (loadYaml(File('constants.yaml').readAsStringSync()) as Map)
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
