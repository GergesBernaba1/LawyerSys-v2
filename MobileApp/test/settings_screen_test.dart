import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadaya_lawyersys/core/storage/preferences_storage.dart';
import 'package:qadaya_lawyersys/features/settings/screens/settings_screen.dart';

void main() {
  testWidgets('settings screen push notification toggle persists', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'languageCode': 'en',
      'pushNotificationEnabled': true,
    });

    final preferences = PreferencesStorage();
    final initialValue = await preferences.getPushNotificationEnabled();
    expect(initialValue, true);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Push Notifications'), findsOneWidget);
    final switchFinder = find.byType(SwitchListTile);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    final persistedValue = await preferences.getPushNotificationEnabled();
    expect(persistedValue, false);
  });
}
