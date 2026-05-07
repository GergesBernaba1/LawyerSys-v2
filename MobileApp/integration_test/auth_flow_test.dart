// Integration tests for authentication flow
// Run with: flutter test integration_test/auth_flow_test.dart
// Requires: backend server running and test credentials configured

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qadaya_lawyersys/main.dart' as app;

/// Test credentials - update these to match your test environment
const String testEmail = 'test@example.com';
const String testPassword = 'Test123!';
const String invalidEmail = 'invalid@example.com';
const String invalidPassword = 'wrong';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('App launches and shows login screen', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify login screen elements are present
      expect(find.text('Login'), findsWidgets);
      expect(find.byType(TextField), findsAtLeastNWidgets(2));
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
    });

    testWidgets('Login with valid credentials succeeds', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find email and password fields
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      // Enter valid credentials
      await tester.enterText(emailField, testEmail);
      await tester.enterText(passwordField, testPassword);
      await tester.pumpAndSettle();

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Login').first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we're on the main screen (look for navigation elements)
      expect(
        find.byType(BottomNavigationBar).or(find.byType(NavigationBar)),
        findsOneWidget,
        reason: 'Main screen should have navigation bar after successful login',
      );
    }, skip: true,); // Enable when backend is available

    testWidgets('Login with invalid credentials shows error', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Find email and password fields
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      // Enter invalid credentials
      await tester.enterText(emailField, invalidEmail);
      await tester.enterText(passwordField, invalidPassword);
      await tester.pumpAndSettle();

      // Tap login button
      final loginButton = find.widgetWithText(ElevatedButton, 'Login').first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify error message is shown
      expect(
        find.byType(SnackBar).or(find.text('Invalid credentials')),
        findsOneWidget,
        reason: 'Error should be displayed for invalid login',
      );

      // Verify we're still on login screen
      expect(find.text('Login'), findsWidgets);
    }, skip: true,); // Enable when backend is available

    testWidgets('Logout flow returns to login screen', (tester) async {
      // Launch the app and login first
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

      // Find and tap profile/settings icon
      final profileIcon = find.byIcon(Icons.person).or(
        find.byIcon(Icons.account_circle),
      );
      await tester.tap(profileIcon);
      await tester.pumpAndSettle();

      // Find and tap logout button
      final logoutButton = find.widgetWithText(
        ElevatedButton,
        RegExp('Logout|Sign Out', caseSensitive: false),
      );
      await tester.tap(logoutButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're back on login screen
      expect(find.text('Login'), findsWidgets);
      expect(find.byType(TextField), findsAtLeastNWidgets(2));
    }, skip: true,); // Enable when backend is available

    testWidgets('Empty email/password shows validation error', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Try to login without entering credentials
      final loginButton = find.widgetWithText(ElevatedButton, 'Login').first;
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify validation errors are shown
      expect(
        find.textContaining(RegExp('required|empty', caseSensitive: false)),
        findsAtLeastNWidgets(1),
        reason: 'Validation errors should be shown for empty fields',
      );
    });

    testWidgets('Biometric authentication flow (if enabled)', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Look for biometric authentication button
      final biometricButton = find.byIcon(Icons.fingerprint).or(
        find.byIcon(Icons.face),
      );

      if (biometricButton.evaluate().isNotEmpty) {
        // Tap biometric button
        await tester.tap(biometricButton);
        await tester.pumpAndSettle();

        // Note: Actual biometric authentication cannot be tested in integration tests
        // We just verify the button is accessible
        expect(biometricButton, findsOneWidget);
      }
    }, skip: true,); // Enable when biometric is configured

    testWidgets('Session persistence - app restart maintains login', (tester) async {
      // Login first
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

      // Simulate app restart
      await tester.restartAndRestore();
      await tester.pumpAndSettle();

      // Verify we're still logged in (main screen should be visible)
      expect(
        find.byType(BottomNavigationBar).or(find.byType(NavigationBar)),
        findsOneWidget,
        reason: 'User should remain logged in after app restart',
      );
    }, skip: true,); // Enable when backend is available

    testWidgets('Token expiration triggers re-authentication', (tester) async {
      // This test would require backend support to expire tokens
      // and verify the app handles it gracefully
    }, skip: true,); // Requires backend token expiration simulation
  });
}
