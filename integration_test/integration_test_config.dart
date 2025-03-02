// integration_test/login_test.dart

import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitmate/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('full login flow test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login page
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      // Test cases will go here...
    });
  });
}