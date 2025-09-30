import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:test/test.dart';

import '../common.dart';

const _hostName = 'tasks.googleapis.com';
const _rootPath = '/v1/';

MockClient mockClient() => MockClient(_hostName, _rootPath);

void main() {
  group('task', () {
    test('create', () {
      final task = tasks.Task();
      // expect(task.name, 'test-task');
    });
  });
}
