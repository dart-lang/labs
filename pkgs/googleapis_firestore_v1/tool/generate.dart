// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Run this script to regenerate the gRPC library from the protobufs.
library;

import 'dart:io';

import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final src = Directory('protos');
  final dst = Directory('lib');

  await protoc(src, dst);

  // TODO(devoncarew): We need on option to not generate the pbjson files.
  final jsonFiles = dst
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.pbjson.dart'));
  for (final jsonFile in jsonFiles) {
    jsonFile.deleteSync();
  }
}

Future<void> protoc(Directory source, Directory dest) async {
  final files = source
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.proto'));
  final names = files.map(
    (file) => path.relative(file.path, from: source.path),
  );

  final protocPlugin = Platform.script.resolve('protoc_plugin.sh').toFilePath();

  final args = <String>[
    // The protos include path.
    '--proto_path=${source.path}',
    // Where to write the generated Dart code.
    '--dart_out=grpc:${dest.path}',
    // protoc_plugin.sh trampolines into package:protoc_plugin.
    '--plugin=dart=$protocPlugin',
    // The proto files to compile.
    ...names,
  ];
  print('protoc ${args.join(' ')}');

  final result = await Process.run('protoc', args);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    throw 'protoc exited with ${result.exitCode}';
  }
}
