// Integration tests for LawyerSys mobile app.
// These tests require a device/emulator and a running backend.
// Run with: flutter test integration_test/app_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows splash or login', (tester) async {
    // TODO: boot the full App() widget and verify the splash / login route renders.
    // Skipped until a test backend is available.
  }, skip: true,); // Requires running backend

  testWidgets('Login flow: valid credentials reach main screen', (tester) async {
    // TODO: enter valid test credentials and assert MainScreen is shown.
  }, skip: true,); // Requires running backend

  testWidgets('Case CRUD: create, view, delete', (tester) async {
    // TODO: create a case, verify it appears in the list, delete it.
  }, skip: true,); // Requires running backend
}
