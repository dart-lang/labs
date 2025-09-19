import 'package:integration_test/integration_test.dart';
import '../../test/dirent_test.dart' as dirent_test;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  dirent_test.main();
}
