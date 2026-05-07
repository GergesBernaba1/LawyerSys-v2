import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN_HERE'; // TODO: Replace with actual Sentry DSN
      options.tracesSampleRate = 1.0;
      options.environment = const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
      options.beforeSend = (event, hint) {
        // Filter out sensitive data before sending to Sentry
        return event;
      };
    },
    appRunner: () => runApp(const App()),
  );
}
