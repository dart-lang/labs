/// This library provides a low-level API for accessing Google's Cloud
/// Tasks.
///
/// For more information on Cloud Tasks, please refer to the following
/// developers page: https://cloud.google.com/tasks/docs
library;

import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:http/http.dart' as http;

import 'service_scope.dart' as ss;

import 'src/tasks_impl.dart' show TasksImpl;

const Symbol _tasksKey = #gcloud.tasks;

/// Access the [Tasks] object available in the current service scope.
///
/// The returned object will be the one which was previously registered with
/// [registerTasksService] within the current (or a parent) service scope.
///
/// Accessing this getter outside of a service scope will result in an error.
/// See the `package:gcloud/service_scope.dart` library for more information.
Tasks get tasksService => ss.lookup(_tasksKey) as Tasks;

/// Registers the [Tasks] object within the current service scope.
///
/// The provided `tasks` object will be available via the top-level
/// `tasksService` getter.
///
/// Calling this function outside of a service scope will result in an error.
/// Calling this function more than once inside the same service scope is not
/// allowed.
void registerTasksService(Tasks tasks) {
  ss.register(_tasksKey, tasks);
}

/// Interface used to talk to the Google Cloud Tasks service.
abstract class Tasks {
  /// List of required OAuth2 scopes for Tasks operations.
  // ignore: constant_identifier_names
  static const Scopes = [tasks.TasksApi.tasksScope];

  /// Access Tasks using an authenticated client.
  ///
  /// The [client] is an authenticated HTTP client. This client must
  /// provide access to at least the scopes in [Tasks.Scopes].
  factory Tasks(http.Client client) {
    return TasksImpl(client);
  }

  /// Creates a new task on the specified task list.
  Future<tasks.Task> createTask(String taskList, tasks.Task task);
}
