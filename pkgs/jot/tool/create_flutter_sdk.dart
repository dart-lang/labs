// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart' as p;

// todo: generate for flutter and some core packges
//   characters: 1.3.0
//   collection: 1.17.1
//   js: 0.6.7
//   material_color_utilities: 0.3.0
//   meta: 1.9.1
//   vector_math: 2.1.4
//   sky_engine:

// flutter_test

// todo: add workspace separators (named and unnamed)
//       (or use a named group?)

// todo: add the flutter sdk (flutter and flutter_test)

// todo: add a placeholder for the dart sdk

// todo: add an area for general packages

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
  var sdkDir = rest.isEmpty
      ? calcFlutterSdk(detectDartSdk)
      : Directory(rest.first);
  if (!sdkDir.existsSync()) {
    stderr.writeln("error: '${sdkDir.path}' does not exist.");
    exit(1);
  }

  validateFlutterSdk(sdkDir);

  var outDir = Directory(results['output'] as String);

  await generate(sdkDir, outDir);
}

Directory get detectDartSdk {
  final vm = Platform.resolvedExecutable;
  // <dart-sdk>/bin/dart
  return Directory(p.dirname(p.dirname(vm)));
}

Directory calcFlutterSdk(Directory dartSdk) {
  // flutter/bin/cache/dart-sdk
  return dartSdk.parent.parent.parent;
}

void printUsage(ArgParser parser, [Object? error]) {
  if (error != null) {
    print(error);
  } else {
    print('Generate API documentation for the Flutter SDK.');
  }

  print('');

  print('usage: dart tool/create_flutter_sdk.dart <options> [<sdk directory>]');
  print('');
  print(parser.usage);
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
      defaultsTo: 'doc/sdk',
      help: 'Configure the output directory.',
    );
}

void validateFlutterSdk(Directory sdk) {
  // bin/
  // packages/
  // packages/flutter/pubspec.yaml

  // todo: also validate whether pub get has been run for the packages

  var binDir = Directory(p.join(sdk.path, 'bin'));
  if (!binDir.existsSync()) {
    stderr.writeln('Invalid SDK (${sdk.path}) - missing bin/ directory');
    exit(1);
  }

  var packagesDir = Directory(p.join(sdk.path, 'packages'));
  if (!packagesDir.existsSync()) {
    stderr.writeln('Invalid SDK (${sdk.path}) - missing packages/ directory');
    exit(1);
  }

  var flutterPubspec = File(
    p.join(sdk.path, 'packages', 'flutter', 'pubspec.yaml'),
  );
  if (!flutterPubspec.existsSync()) {
    stderr.writeln(
      'Invalid SDK (${sdk.path}) - missing packages/flutter/pubspec.yaml file',
    );
    exit(1);
  }
}

Future<void> generate(Directory sdkDir, Directory outDir) async {
  var log = Logger.standard();

  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  log.stdout('todo: generate docs for the flutter SDK');
}
