// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:jot/jot.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support.dart';

// Server (--serve) integration tests using test/fixtures/demo.

void main() {
  group('server', () {
    late final DocServer server;
    late final Directory tempDir;

    setUpAll(() async {
      final sourceDir = Directory(p.join('test', 'fixtures', 'server'));
      tempDir = Directory.systemTemp.createTempSync('jot');

      final jot = Jot(inDir: sourceDir, outDir: tempDir, logger: NullLogger());
      server = await jot.serve(0);
    });

    tearDownAll(() async {
      tempDir.deleteSync(recursive: true);
      await server.dispose();
    });

    test('index.html', () async {
      final response = await http.read(
        Uri.http('localhost:${server.port}', 'index.html'),
      );
      expect(response, contains('<title>package:server_demo</title>'));
    });

    test('a.html', () async {
      var response = await http.read(
        Uri.http('localhost:${server.port}', 'a.html'),
      );
      expect(response, contains('<h1>a.dart</h1>'));
      expect(response, contains('bar('));
      expect(response, contains('Classes'));

      response = await http.read(
        Uri.http('localhost:${server.port}', 'a/A.html'),
      );
      expect(response, contains('<h1>A</h1>'));
      expect(response, contains('class A'));
      expect(response, contains('foo()'));
    });

    test('b.html', () async {
      final response = await http.read(
        Uri.http('localhost:${server.port}', 'b.html'),
      );
      expect(response, contains('<h1>b.dart</h1>'));
      expect(response, contains('baz('));
      expect(response, isNot(contains('Classes')));
    });
  });
}
