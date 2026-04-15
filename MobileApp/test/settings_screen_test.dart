import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadaya_lawyersys/core/storage/preferences_storage.dart';
import 'package:qadaya_lawyersys/features/authentication/repositories/auth_repository.dart';
import 'package:qadaya_lawyersys/features/settings/screens/settings_screen.dart';
import 'auth_flow_test.mocks.dart';

void main() {
  testWidgets('settings screen push notification toggle persists', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'languageCode': 'en',
      'pushNotificationEnabled': true,
    });

    final preferences = PreferencesStorage();
    final initialValue = await preferences.getPushNotificationEnabled();
    expect(initialValue, true);

    final mockAuth = MockAuthRepository();
    final mockBiometric = MockBiometricAuthService();

    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>(
        create: (_) => mockAuth,
        child: MaterialApp(
          home: SettingsScreen(biometricAuthService: mockBiometric),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final switchFinder = find.byType(SwitchListTile);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final persistedValue = await preferences.getPushNotificationEnabled();
    expect(persistedValue, false);
  });
}
