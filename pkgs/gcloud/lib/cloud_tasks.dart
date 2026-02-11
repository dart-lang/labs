/// This library provides a low-level API for accessing Google's Cloud
/// Tasks.
///
/// For more information on Cloud Tasks, please refer to the following
/// developers page: https://cloud.google.com/tasks/docs
library;

import 'package:googleapis/cloudtasks/v2.dart' as tasks;
import 'package:http/http.dart' as http;

import 'service_scope.dart' as ss;

import 'src/cloud_tasks_impl.dart' show CloudTasksImpl;

const Symbol _tasksKey = #gcloud.tasks;

/// Access the [CloudTasks] object available in the current service scope.
///
/// The returned object will be the one which was previously registered with
/// [registerTasksService] within the current (or a parent) service scope.
///
/// Accessing this getter outside of a service scope will result in an error.
/// See the `package:gcloud/service_scope.dart` library for more information.
CloudTasks get tasksService => ss.lookup(_tasksKey) as CloudTasks;

/// Registers the [CloudTasks] object within the current service scope.
///
/// The provided `tasks` object will be available via the top-level
/// `tasksService` getter.
///
/// Calling this function outside of a service scope will result in an error.
/// Calling this function more than once inside the same service scope is not
/// allowed.
void registerTasksService(CloudTasks tasks) {
  ss.register(_tasksKey, tasks);
}

/// Interface used to talk to the Google Cloud Tasks service.
abstract class CloudTasks {
  /// List of required OAuth2 scopes for Cloud Tasks operations.
  // ignore: constant_identifier_names
  static const Scopes = [tasks.CloudTasksApi.cloudPlatformScope];

  /// Access Cloud Tasks using an authenticated client.
  ///
  /// The [client] is an authenticated HTTP client. This client must
  /// provide access to at least the scopes in [CloudTasks.Scopes].
  factory CloudTasks(http.Client client, String project, String location) {
    return CloudTasksImpl(client, project, location);
  }

  /// Creates a new task on the specified [queue]. When the task is run,
  /// [request] will be executed.
  ///
  /// If [scheduleTime] is provided, the task will be scheduled to run at the
  /// specified time. If not provided, the task will be scheduled to run
  /// immediately.
  ///
  /// If [name] is provided, the task will be given that name.
  ///
  /// Returns a [Future] which completes with the newly created task.
  Future<tasks.Task> createTask(
    String queue,
    http.Request request, {
    String? name,
    DateTime? scheduleTime,
  });
}
