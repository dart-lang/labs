// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:jot/jot.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  var parser = createArgsParser();
  ArgResults results;

  try {
    results = parser.parse(args);
  } catch (e) {
    printUsage(parser, e);
    exit(64);
  }

  var help = results['help'] as bool;
  if (help) {
    printUsage(parser);
    exit(0);
  }

  var rest = results.rest;
  var inDir = rest.isEmpty ? Directory.current : Directory(rest.first);
  if (!inDir.existsSync()) {
    stderr.writeln("error: '${inDir.path}' does not exist.");
    exit(1);
  }

  Directory outDir;
  if (results.wasParsed('output')) {
    outDir = Directory(results['output'] as String);
  } else {
    outDir = Directory(p.join(inDir.path, results['output'] as String));
  }

  int? servePort;
  if (results.wasParsed('serve')) {
    servePort = int.tryParse(results['serve'] as String);
  }

  final markdown = results['markdown'] as bool;

  var jot = Jot(inDir: inDir, outDir: outDir, markdown: markdown);

  if (servePort == null) {
    await jot.generate();
  } else {
    await jot.serve(servePort);
  }
}

ArgParser createArgsParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this command help.',
    )
    ..addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'doc/api',
      help: 'Configure the output directory.',
    )
    ..addFlag(
      'markdown',
      aliases: ['md', 'llm'],
      negatable: true,
      defaultsTo: true,
      help: 'Include LLM-friendly markdown summaries of the API.',
    )
    ..addOption(
      'serve',
      valueHelp: 'port',
      help:
          'Serve live docs from the documented package.\nThis serves on '
          'localhost and is useful for previewing docs while working on them.',
    );
}

void printUsage(ArgParser parser, [Object? error]) {
  if (error != null) {
    print(error);
  } else {
    print('Generate API documentation for Dart projects.');
  }

  print('');

  print('usage: dart bin/jot.dart <options> [<directory>]');
  print('');
  print(parser.usage);
}
