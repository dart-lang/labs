import 'package:googleapis/tasks/v1.dart' as api;
import 'package:http/http.dart' as http;

import '../tasks.dart' as tasks;

class TasksImpl implements tasks.Tasks {
  final api.TasksApi _api;

  TasksImpl(http.Client client) : _api = api.TasksApi(client);

  @override
  Future<api.Task> createTask(String taskList, api.Task task) {
    return _api.tasks.insert(task, taskList);
  }
}
