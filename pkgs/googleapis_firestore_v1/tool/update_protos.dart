// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Run this script to update to the latest google/protobuf and googleapis
/// protobufs.
library;

import 'dart:io';

void main(List<String> args) async {
  final cacheDir = Directory('.dart_tool/googleapis_firestore_v1');
  final protobufDir = Directory('.dart_tool/protobuf');
  final googleapisDir = Directory('.dart_tool/googleapis');

  final destDir = Directory('protos');

  if (protobufDir.existsSync()) {
    await git(['pull', '--depth', '1'], cwd: protobufDir);
  } else {
    await git([
      'clone',
      'https://github.com/protocolbuffers/protobuf.git',
      '--depth',
      '1',
    ], cwd: cacheDir);
  }

  copy(protobufDir, destDir, 'src', [
    'google/protobuf/any.proto',
    'google/protobuf/duration.proto',
    'google/protobuf/empty.proto',
    'google/protobuf/struct.proto',
    'google/protobuf/timestamp.proto',
    'google/protobuf/wrappers.proto',
  ]);

  print('');

  if (googleapisDir.existsSync()) {
    await git(['pull'], cwd: googleapisDir);
  } else {
    await git([
      'clone',
      'https://github.com/googleapis/googleapis.git',
      '--depth',
      '1',
    ], cwd: cacheDir);
  }

  copy(googleapisDir, destDir, '', [
    'google/api/annotations.proto',
    'google/api/client.proto',
    'google/api/field_behavior.proto',
    'google/api/http.proto',
    'google/api/launch_stage.proto',
    'google/api/routing.proto',
    'google/firestore/v1/aggregation_result.proto',
    'google/firestore/v1/bloom_filter.proto',
    'google/firestore/v1/common.proto',
    'google/firestore/v1/document.proto',
    'google/firestore/v1/firestore.proto',
    'google/firestore/v1/query_profile.proto',
    'google/firestore/v1/query.proto',
    'google/firestore/v1/write.proto',
    'google/firestore/v1/write.proto',
    'google/rpc/status.proto',
    'google/type/latlng.proto',
  ]);
}

Future<void> git(List<String> args, {required Directory cwd}) async {
  print('git ${args.join(' ')} [${cwd.path}]');

  final result = await Process.run('git', args, workingDirectory: cwd.path);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    throw 'git exited with ${result.exitCode}';
  }
}

void copy(Directory from, Directory to, String fromPrefix, List<String> files) {
  print('copying ${from.path} => ${to.path}');

  if (fromPrefix.isNotEmpty) {
    fromPrefix = '$fromPrefix/';
  }

  for (final file in files) {
    final source = File('${from.path}/$fromPrefix$file');
    final target = File('${to.path}/$file');

    if (!target.parent.existsSync()) {
      target.parent.createSync(recursive: true);
    }

    if (!target.existsSync() ||
        target.readAsStringSync() != source.readAsStringSync()) {
      print('  $file');
      target.writeAsStringSync(source.readAsStringSync());
    }
  }
}
