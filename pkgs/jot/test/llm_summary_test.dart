// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:jot/api.dart';
import 'package:jot/src/llm_summary.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support.dart';

// LLM markdown summary integration tests using test/fixtures/demo.

void main() {
  group('signature', () {
    late final TestProject demoProject;

    setUpAll(() async {
      demoProject = TestProject.fromTemplate(
        Directory(p.join('test', 'fixtures', 'demo')),
      );
      await demoProject.init();
    });

    tearDownAll(() {
      demoProject.dispose();
    });

    Directory? tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
    });

    tearDown(() {
      tempDir?.deleteSync();
    });

    LibraryItemContainer library(String name) {
      final package = demoProject.workspace.api.packages.single;
      return package.libraries.firstWhere((lib) => lib.name == name);
    }

    test('demo.dart', () {
      final sig = LLMSummary(
        workspace: demoProject.workspace,
        outDir: tempDir!,
        logger: NullLogger(),
      );

      final actual = sig.generateForLibrary(library('demo.dart'));
      expect(actual, golden('demo.md'));
    });

    test('modifiers_a.dart', () {
      final sig = LLMSummary(
        workspace: demoProject.workspace,
        outDir: tempDir!,
        logger: NullLogger(),
      );

      final actual = sig.generateForLibrary(library('modifiers_a.dart'));
      expect(actual, golden('modifiers_a.md'));
    });

    test('modifiers_b.dart', () {
      final sig = LLMSummary(
        workspace: demoProject.workspace,
        outDir: tempDir!,
        logger: NullLogger(),
      );

      final actual = sig.generateForLibrary(library('modifiers_b.dart'));
      expect(actual, golden('modifiers_b.md'));
    });
  });
}

String golden(String sigName) {
  final path = p.join('test', 'fixtures', 'demo', 'doc', 'api', sigName);
  return File(path).readAsStringSync();
}
