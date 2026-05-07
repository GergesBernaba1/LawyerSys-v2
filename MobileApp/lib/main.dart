import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:qadaya_lawyersys/app.dart';
import 'package:qadaya_lawyersys/core/notifications/notification_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(NotificationHandler.firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  await SentryFlutter.init(
    (options) {
      options
        ..dsn = 'YOUR_SENTRY_DSN_HERE' // TODO: Replace with actual Sentry DSN
        ..tracesSampleRate = 1.0
        ..environment = const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development')
        ..beforeSend = (event, hint) {
          return event;
        };
    },
    appRunner: () => runApp(const App()),
  );
}
