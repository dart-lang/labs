import 'dart:convert';

import 'package:gcloud/cloud_tasks.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import '../common.dart';
import '../common_e2e.dart';

const _hostName = 'cloudtasks.googleapis.com';
const _rootPath = '/v2/';
const _defaultLocation = 'us-central1';

MockClient mockClient() => MockClient(_hostName, _rootPath);

Future<void> withMockClientAsync(
    Future Function(MockClient client, CloudTasks tasks) function) async {
  var mock = mockClient();
  await function(mock, CloudTasks(mock, testProject, _defaultLocation));
}

void main() {
  group('task', () {
    test('create with httpRequest', () async {
      const taskName = 'my-task';
      const requestBody = 'hello world';
      const requestHeaders = {
        'content-type': 'application/json',
        'authorization': 'Bearer ....'
      };
      final expectedTaskJson = {
        'name': taskName,
        'httpRequest': {
          'headers': requestHeaders,
          'body': base64.encode(utf8.encode(requestBody)),
          'httpMethod': 'GET',
          'url': 'https://www.google.com',
        },
      };
      final responseJson = {'task': expectedTaskJson};

      await withMockClientAsync((mock, tasks) async {
        mock.register(
          'POST',
          'projects/test-project/locations/us-central1/queues/test-queue/tasks',
          expectAsync1((request) {
            final json = jsonDecode(request.body) as Map<String, dynamic>;
            expect(json, responseJson);
            return mock.respond(expectedTaskJson);
          }),
        );

        final request = http.Request('GET', Uri.parse('https://www.google.com'))
          ..body = requestBody
          ..headers.addAll(requestHeaders);

        final task =
            await tasks.createTask('test-queue', request, name: taskName);
        expect(task.name, taskName);
        final actualRequestJson = task.httpRequest!.toJson();
        expect(actualRequestJson, expectedTaskJson['httpRequest']);
      });
    });
  });
}
