import 'dart:convert';

import 'package:googleapis/cloudtasks/v2.dart' as api;
import 'package:http/http.dart' as http;

import '../cloud_tasks.dart' as tasks;

class CloudTasksImpl implements tasks.CloudTasks {
  final api.CloudTasksApi _api;
  final String _project;
  final String _location;

  CloudTasksImpl(http.Client client, String project, String location)
      : _api = api.CloudTasksApi(client),
        _project = project,
        _location = location;

  @override
  Future<api.Task> createTask(
    String queue,
    http.Request request, {
    DateTime? scheduleTime,
    String? name,
  }) async {
    final task = api.Task(
      name: name,
      scheduleTime: scheduleTime?.toUtc().toIso8601String(),
      httpRequest: _fromHttpRequest(request),
    );
    final createTaskRequest = api.CreateTaskRequest(task: task);
    return _api.projects.locations.queues.tasks
        .create(createTaskRequest, _fullQueueName(queue));
  }

  api.HttpRequest _fromHttpRequest(http.Request request) {
    return api.HttpRequest(
      headers: request.headers,
      body: base64.encode(utf8.encode(request.body)),
      httpMethod: request.method,
      url: request.url.toString(),
    );
  }

  String _fullQueueName(String name) {
    return 'projects/$_project/locations/$_location/queues/$name';
  }
}
