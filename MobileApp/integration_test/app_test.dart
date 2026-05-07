// Integration tests for LawyerSys mobile app.
// These tests require a device/emulator and a running backend.
// Run with: flutter test integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qadaya_lawyersys/main.dart' as app;

import 'test_helpers.dart';

/// Test credentials - update these to match your test environment
const String testEmail = 'test@example.com';
const String testPassword = 'Test123!';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows splash or login', (tester) async {
    // Boot the full App() widget
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify the splash or login route renders
    // Should show either a splash screen or login screen
    expect(
      findAnyOf([
        findTextContaining('LawyerSys|Qadaya|قضايا', caseSensitive: false),
        find.byType(TextField),
        findTextByPattern('Login|Sign In|تسجيل الدخول', caseSensitive: false),
      ]),
      findsWidgets,
      reason: 'App should show splash or login screen on launch',
    );

    // Wait for any splash screen to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // After splash, should show login screen
    expect(
      findAnyOf([
        find.byType(TextField),
        findTextByPattern('Login|Sign In|تسجيل الدخول', caseSensitive: false),
      ]),
      findsWidgets,
      reason: 'Login screen should be visible after splash',
    );
  }, skip: true,); // Requires running backend

  testWidgets('Login flow: valid credentials reach main screen', (tester) async {
    // Launch app and wait for login screen
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Find email and password fields
    final textFields = find.byType(TextField);
    expect(textFields, findsAtLeastNWidgets(2), reason: 'Login form should have email and password fields');

    final emailField = textFields.first;
    final passwordField = textFields.at(1);

    // Enter valid test credentials
    await tester.enterText(emailField, testEmail);
    await tester.pumpAndSettle();
    await tester.enterText(passwordField, testPassword);
    await tester.pumpAndSettle();

    // Find and tap login button
    final loginButton = findAnyOf([
      findWidgetWithTextPattern<ElevatedButton>('Login|Sign In|تسجيل الدخول', caseSensitive: false),
      findTextByPattern('Login|Sign In|تسجيل الدخول', caseSensitive: false),
    ]);
    expect(loginButton, findsWidgets, reason: 'Login button should be visible');

    await tester.tap(loginButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Assert MainScreen/DashboardScreen is shown
    // Look for common dashboard elements
    expect(
      findAnyOf([
        findTextByPattern('Dashboard|Home|الرئيسية', caseSensitive: false),
        findTextByPattern('Cases|القضايا', caseSensitive: false),
        find.byType(BottomNavigationBar),
        find.byIcon(Icons.menu),
      ]),
      findsWidgets,
      reason: 'Main screen should be visible after successful login',
    );

    // Verify we are no longer on login screen
    expect(
      find.byType(TextField).hitTestable(),
      findsNothing,
      reason: 'Login fields should not be visible after successful login',
    );
  }, skip: true,); // Requires running backend

  testWidgets('Case CRUD: create, view, delete', (tester) async {
    // Login first
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, testEmail);
    await tester.enterText(textFields.at(1), testPassword);
    await tester.pumpAndSettle();

    final loginButton = findTextByPattern('Login|Sign In|تسجيل الدخول', caseSensitive: false);
    await tester.tap(loginButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Navigate to cases screen
    final casesNav = findTextByPattern('Cases|القضايا', caseSensitive: false);
    if (casesNav.evaluate().isNotEmpty) {
      await tester.tap(casesNav.first);
      await tester.pumpAndSettle();
    } else {
      // Try finding by icon
      final casesIcon = findAnyOf([find.byIcon(Icons.gavel), find.byIcon(Icons.work)]);
      if (casesIcon.evaluate().isNotEmpty) {
        await tester.tap(casesIcon.first);
        await tester.pumpAndSettle();
      }
    }

    // Wait for cases list to load
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Create a new case
    final addButton = findAnyOf([
      find.byIcon(Icons.add),
      find.widgetWithIcon(FloatingActionButton, Icons.add),
    ]);
    expect(addButton, findsWidgets, reason: 'Add case button should be visible');

    await tester.tap(addButton.first);
    await tester.pumpAndSettle();

    // Fill in case details
    final caseFormFields = find.byType(TextField);
    if (caseFormFields.evaluate().isNotEmpty) {
      // Enter test case data
      await tester.enterText(caseFormFields.first, 'Test Case ${DateTime.now().millisecondsSinceEpoch}');
      await tester.pumpAndSettle();

      // Find and tap save button
      final saveButton = findAnyOf([
        findWidgetWithTextPattern<ElevatedButton>('Save|Create|حفظ|إنشاء', caseSensitive: false),
        findTextByPattern('Save|Create|حفظ|إنشاء', caseSensitive: false),
      ]);
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify case appears in the list
        expect(
          find.text('Test Case').hitTestable(),
          findsWidgets,
          reason: 'Created case should appear in cases list',
        );

        // Delete the case - find delete button or menu
        final deleteAction = findAnyOf([
          find.byIcon(Icons.delete),
          find.byIcon(Icons.more_vert),
        ]);
        if (deleteAction.evaluate().isNotEmpty) {
          await tester.tap(deleteAction.first);
          await tester.pumpAndSettle();

          // Confirm deletion if dialog appears
          final confirmDelete = findTextByPattern('Delete|Confirm|حذف|تأكيد', caseSensitive: false);
          if (confirmDelete.evaluate().isNotEmpty) {
            await tester.tap(confirmDelete.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }
        }
      }
    }
  }, skip: true,); // Requires running backend
}
