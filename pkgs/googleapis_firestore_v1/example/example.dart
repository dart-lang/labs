// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:googleapis_firestore_v1/google/firestore/v1/common.pb.dart';
import 'package:googleapis_firestore_v1/google/firestore/v1/document.pb.dart';
import 'package:googleapis_firestore_v1/google/firestore/v1/firestore.pbgrpc.dart';
import 'package:grpc/grpc.dart' as grpc;

void main(List<String> args) async {
  final commandRunner = createCommandRunner();
  final result = await commandRunner.run(args);
  exit(result ?? 0);
}

CommandRunner<int> createCommandRunner() {
  final runner = CommandRunner<int>(
    'firestore',
    'A sample app exercising the Firestore APIs',
  )..argParser.addOption(
      'project',
      valueHelp: 'projectId',
      help: 'The projectId to use when querying a firestore database.',
    );

  runner.addCommand(ListCommand());
  runner.addCommand(PeekCommand());
  runner.addCommand(PokeCommand());
  runner.addCommand(ListenCommand());

  return runner;
}

class ListCommand extends FirestoreCommand {
  @override
  final String name = 'list';

  @override
  final String description = 'List collections for the given project.';

  @override
  Future<int> runCommand(FirestoreClient firestore) async {
    final request = ListCollectionIdsRequest(parent: documentsPath);
    print('Listing collections for ${request.parent}…');
    final result = await firestore.listCollectionIds(request);
    print('');
    for (var collectionId in result.collectionIds) {
      print('- $collectionId');
    }
    print('');
    print('${result.collectionIds.length} collections.');
    return 0;
  }
}

class PeekCommand extends FirestoreCommand {
  @override
  final String name = 'peek';

  @override
  final String description =
      "Print the value of collection 'demo', document 'demo', field 'item'.";

  @override
  Future<int> runCommand(FirestoreClient firestore) async {
    final request = GetDocumentRequest(name: '$documentsPath/demo/demo');
    print('reading ${request.name}…');
    final document = await firestore.getDocument(request);
    final value = document.fields['item'];
    if (value == null) {
      print("No value for document field 'item'.");
    } else {
      print("value: '${value.stringValue}'");
    }
    final updateTime = document.updateTime.toDateTime();
    print('updated: $updateTime');

    return 0;
  }
}

class PokeCommand extends FirestoreCommand {
  @override
  final String name = 'poke';

  @override
  final String description =
      "Set the value of collection 'demo', document 'demo', field 'item'.";

  @override
  String get invocation => '${super.invocation} <new value>';

  @override
  Future<int> runCommand(FirestoreClient firestore) async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      print(usage);
      return 1;
    }

    final newValue = rest.first;
    print("Updating demo/demo.item to '$newValue'…");

    final updatedDocument = Document(
      name: '$documentsPath/demo/demo',
      fields: [
        MapEntry('item', Value(stringValue: newValue)),
      ],
    );
    await firestore.updateDocument(
      UpdateDocumentRequest(
        document: updatedDocument,
        updateMask: DocumentMask(fieldPaths: ['item']),
      ),
    );

    return 0;
  }
}

class ListenCommand extends FirestoreCommand {
  @override
  final String name = 'listen';

  @override
  final String description =
      "Listen for changes to the 'item' field of document 'demo' in "
      "collection 'demo'.";

  @override
  Future<int> runCommand(FirestoreClient firestore) async {
    print('Listening for changes to demo.item field (hit ctrl-c to stop).');
    print('');

    final StreamController<ListenRequest> requestSink = StreamController();

    // Listen for 'ctrl-c' and close the firestore.listen stream.
    ProcessSignal.sigint.watch().listen((_) => requestSink.close());

    final ListenRequest listenRequest = ListenRequest(
      database: databaseId,
      addTarget: Target(
        documents: Target_DocumentsTarget(
          documents: [
            '$documentsPath/demo/demo',
          ],
        ),
        targetId: 1,
      ),
    );

    final Stream<ListenResponse> stream = firestore.listen(
      requestSink.stream,
      // TODO(devoncarew): We add this routing header because our protoc grpc
      // generator doesn't yet parse the http proto annotations.
      options: grpc.CallOptions(
        metadata: {
          'x-goog-request-params': 'database=$databaseId',
        },
      ),
    );

    requestSink.add(listenRequest);

    final streamClosed = Completer();

    stream.listen(
      (event) {
        print('==============');
        print('documentChange: ${event.documentChange.toString().trim()}');
        print('==============');
        print('');
      },
      onError: (e) {
        print('\nError listening to document changes: $e');
        streamClosed.complete();
      },
      onDone: () {
        print('\nListening stream done.');
        streamClosed.complete();
      },
    );

    await streamClosed.future;

    return 0;
  }
}

abstract class FirestoreCommand extends Command<int> {
  String get projectId => globalResults!.option('project')!;

  String get databaseId => 'projects/$projectId/databases/(default)';

  String get documentsPath => '$databaseId/documents';

  @override
  Future<int> run() async {
    final projectId = globalResults!.option('project');
    if (projectId == null) {
      print('A --project option is required.');
      return 1;
    }

    final channel = grpc.ClientChannel(FirestoreClient.defaultHost);
    final auth = await grpc.applicationDefaultCredentialsAuthenticator(
      FirestoreClient.oauthScopes,
    );

    final firestore = FirestoreClient(channel, options: auth.toCallOptions);
    final result = await runCommand(firestore);
    await channel.shutdown();
    return result;
  }

  Future<int> runCommand(FirestoreClient firestore);
}
