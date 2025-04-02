import 'package:integration_test/integration_test.dart';
import '../../test/read_as_bytes_test.dart' as read_as_bytes;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  read_as_bytes.main();
}
