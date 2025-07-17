// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Run all code generation and formatting steps.

import 'dart:io';

import 'package:dart_style/dart_style.dart';

import 'package:ffigen/src/executables/ffigen.dart' as ffigen;
import 'build_constants.dart' as build_constants;

void _formatFile(String path) {
  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );
  final file = File(path);
  file.writeAsStringSync(formatter.format(file.readAsStringSync(), uri: path));
}

void main() async {
  build_constants.main();

  await ffigen.main(['--no-format', '-v', 'severe', '--config', 'ffigen.yaml']);
  await ffigen.main([
    '--no-format',
    '-v',
    'severe',
    '--config',
    'constants-ffigen.yaml',
  ]);

  _formatFile('lib/src/constant_bindings.g.dart');
  _formatFile('lib/src/constants.g.dart');
  _formatFile('lib/src/libc_bindings.g.dart');
}
