// Integration tests for case management flow
// Run with: flutter test integration_test/case_management_test.dart
// Requires: backend server running, test user logged in

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qadaya_lawyersys/main.dart' as app;

/// Test credentials - update these to match your test environment
const String testEmail = 'test@example.com';
const String testPassword = 'Test123!';

/// Helper function to login before tests
Future<void> loginAsTestUser(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  final emailField = find.byType(TextField).first;
  final passwordField = find.byType(TextField).last;
  await tester.enterText(emailField, testEmail);
  await tester.enterText(passwordField, testPassword);
  await tester.pumpAndSettle();

  final loginButton = find.widgetWithText(ElevatedButton, 'Login').first;
  await tester.tap(loginButton);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

/// Helper function to navigate to cases screen
Future<void> navigateToCasesScreen(WidgetTester tester) async {
  // Look for Cases navigation item (could be in bottom nav or drawer)
  final casesNav = find.text(RegExp(r'Cases|القضايا', caseSensitive: false));
  
  if (casesNav.evaluate().isEmpty) {
    // Try finding by icon
    final casesIcon = find.byIcon(Icons.gavel).or(find.byIcon(Icons.work));
    if (casesIcon.evaluate().isNotEmpty) {
      await tester.tap(casesIcon.first);
      await tester.pumpAndSettle();
    }
  } else {
    await tester.tap(casesNav.first);
    await tester.pumpAndSettle();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Case Management Integration Tests', () {
    testWidgets('Cases list loads and displays cases', (tester) async {
      // Login
      await loginAsTestUser(tester);

      // Navigate to cases screen
      await navigateToCasesScreen(tester);

      // Verify cases list or loading indicator is shown
      expect(
        find.byType(ListView).or(find.byType(CircularProgressIndicator)),
        findsOneWidget,
        reason: 'Cases screen should show list or loading indicator',
      );

      // Wait for data to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify cases are displayed (or "no cases" message)
      expect(
        find.byType(ListTile)
            .or(find.textContaining(RegExp(r'No cases|لا توجد قضايا'))),
        findsWidgets,
        reason: 'Should show cases or empty state',
      );
    }, skip: true); // Enable when backend is available

    testWidgets('Create new case flow', (tester) async {
      // Login and navigate to cases
      await loginAsTestUser(tester);
      await navigateToCasesScreen(tester);

      // Find and tap the "add case" button
      final addButton = find.byIcon(Icons.add).or(
        find.widgetWithIcon(FloatingActionButton, Icons.add),
      );
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Verify case form is displayed
      expect(
        find.text(RegExp(r'New Case|Create Case|قضية جديدة')),
        findsOneWidget,
        reason: 'Case creation form should be displayed',
      );

      // Fill in case details
      final caseNumberField = find.widgetWithText(
        TextField,
        RegExp(r'Case Number|رقم القضية'),
      );
      if (caseNumberField.evaluate().isNotEmpty) {
        await tester.enterText(caseNumberField, 'TEST-${DateTime.now().millisecondsSinceEpoch}');
        await tester.pumpAndSettle();
      }

      final titleField = find.widgetWithText(
        TextField,
        RegExp(r'Title|العنوان'),
      );
      if (titleField.evaluate().isNotEmpty) {
        await tester.enterText(titleField, 'Integration Test Case');
        await tester.pumpAndSettle();
      }

      // Tap save/create button
      final saveButton = find.widgetWithText(
        ElevatedButton,
        RegExp(r'Save|Create|حفظ|إنشاء'),
      );
      await tester.tap(saveButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify success message
      expect(
        find.byType(SnackBar).or(find.textContaining(RegExp(r'success|created|تم'))),
        findsOneWidget,
        reason: 'Success message should be displayed after creating case',
      );

      // Verify we're back on cases list
      expect(find.byType(ListView), findsOneWidget);
    }, skip: true); // Enable when backend is available

    testWidgets('View case details', (tester) async {
      // Login and navigate to cases
      await loginAsTestUser(tester);
      await navigateToCasesScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on the first case in the list
      final firstCase = find.byType(ListTile).first;
      await tester.tap(firstCase);
      await tester.pumpAndSettle();

      // Verify case detail screen is displayed
      expect(
        find.text(RegExp(r'Case Details|تفاصيل القضية')),
        findsOneWidget,
        reason: 'Case details screen should be displayed',
      );

      // Verify key details are shown
      expect(
        find.textContaining(RegExp(r'Status|Case Number|Client', caseSensitive: false)),
        findsWidgets,
        reason: 'Case details should be visible',
      );

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify we're back on cases list
      expect(find.byType(ListView), findsOneWidget);
    }, skip: true); // Enable when backend is available

    testWidgets('Edit case details', (tester) async {
      // Login and navigate to cases
      await loginAsTestUser(tester);
      await navigateToCasesScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on the first case
      final firstCase = find.byType(ListTile).first;
      await tester.tap(firstCase);
      await tester.pumpAndSettle();

      // Find and tap edit button
      final editButton = find.byIcon(Icons.edit).or(
        find.widgetWithText(IconButton, RegExp(r'Edit|تعديل')),
      );
      await tester.tap(editButton.first);
      await tester.pumpAndSettle();

      // Modify a field
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Updated Test Case ${DateTime.now().millisecond}');
      await tester.pumpAndSettle();

      // Save changes
      final saveButton = find.widgetWithText(
        ElevatedButton,
        RegExp(r'Save|Update|حفظ|تحديث'),
      );
      await tester.tap(saveButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify success message
      expect(
        find.byType(SnackBar).or(find.textContaining(RegExp(r'updated|success'))),
        findsOneWidget,
        reason: 'Success message should be displayed after update',
      );
    }, skip: true); // Enable when backend is available

    testWidgets('Search cases', (tester) async {
      // Login and navigate to cases
      await loginAsTestUser(tester);
      await navigateToCasesScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find search field
      final searchField = find.widgetWithText(
        TextField,
        RegExp(r'Search|بحث'),
      );
      expect(searchField, findsOneWidget, reason: 'Search field should be visible');

      // Enter search query
      await tester.enterText(searchField, 'test');
      await tester.pumpAndSettle();

      // Submit search (tap search icon or press enter)
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify results are filtered
      expect(
        find.byType(ListView).or(find.textContaining(RegExp(r'No.*found'))),
        findsOneWidget,
        reason: 'Search results should be displayed',
      );

      // Clear search
      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }
    }, skip: true); // Enable when backend is available

    testWidgets('Delete case', (tester) async {
      // Login and navigate to cases
      await loginAsTestUser(tester);
      await navigateToCasesScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Count initial cases
      final initialCaseCount = find.byType(ListTile).evaluate().length;

      // Tap on first case
      final firstCase = find.byType(ListTile).first;
      await tester.tap(firstCase);
      await tester.pumpAndSettle();

      // Find and tap delete button
      final deleteButton = find.byIcon(Icons.delete).or(
        find.widgetWithText(IconButton, RegExp(r'Delete|حذف')),
      );
      await tester.tap(deleteButton.first);
      await tester.pumpAndSettle();

      // Confirm deletion in dialog
      final confirmButton = find.widgetWithText(
        TextButton,
        RegExp(r'Delete|Confirm|Yes|نعم|تأكيد'),
      );
      await tester.tap(confirmButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify success message
      expect(
        find.byType(SnackBar).or(find.textContaining(RegExp(r'deleted|removed'))),
        findsOneWidget,
        reason: 'Delete success message should be displayed',
      );

      // Verify case count decreased
      await tester.pumpAndSettle();
      final finalCaseCount = find.byType(ListTile).evaluate().length;
      expect(
        finalCaseCount,
        lessThan(initialCaseCount),
        reason: 'Case count should decrease after deletion',
      );
    }, skip: true); // Enable when backend is available

    testWidgets('Pagination - scroll to load more cases', (tester) async {
      // Login and navigate to cases
      await loginAsTestUser(tester);
      await navigateToCasesScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Get initial count
      final initialCount = find.byType(ListTile).evaluate().length;

      // Scroll to bottom
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify loading indicator appears or more items loaded
      expect(
        find.byType(CircularProgressIndicator).or(find.byType(ListTile)),
        findsWidgets,
        reason: 'Should show loading indicator or more items',
      );

      // Wait for new items to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify more cases loaded (if there are more than 20 cases)
      final finalCount = find.byType(ListTile).evaluate().length;
      // Note: This may be equal if there are fewer than 20 cases total
      expect(
        finalCount,
        greaterThanOrEqualTo(initialCount),
        reason: 'Should maintain or increase case count after scroll',
      );
    }, skip: true); // Enable when backend has sufficient test data

    testWidgets('Offline mode - displays cached cases', (tester) async {
      // This test would require disabling network access
      // and verifying cached cases are shown
    }, skip: true); // Requires network simulation

    testWidgets('Pull to refresh cases list', (tester) async {
      // Login and navigate to cases
      await loginAsTestUser(tester);
      await navigateToCasesScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Pull down to refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify refresh indicator
      expect(
        find.byType(RefreshIndicator).or(find.byType(CircularProgressIndicator)),
        findsOneWidget,
        reason: 'Refresh indicator should be shown',
      );

      // Wait for refresh to complete
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify list is still displayed
      expect(find.byType(ListView), findsOneWidget);
    }, skip: true); // Enable when backend is available
  });
}
