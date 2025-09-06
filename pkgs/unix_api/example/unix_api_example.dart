import 'package:unix_api/unix_api.dart';

void main() {
  print('I am ${getpid()} and my parent is ${getppid()}');
}
