import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/authentication/repositories/auth_repository.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  AuthRepository? _authRepository;

  void configure(AuthRepository authRepository) {
    _authRepository = authRepository;
  }

  Future<void> init() async {
    await _requestPermission();

    final token = await _messaging.getToken();
    if (token != null && _authRepository != null) {
      await _authRepository!.registerDeviceToken(token);
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      if (newToken.isNotEmpty && _authRepository != null) {
        await _authRepository!.registerDeviceToken(newToken);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      debugPrint('Foreground message: ${event.notification?.title} ${event.notification?.body}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage event) {
      debugPrint('Notification opened-app payload: ${event.data}');
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> disable() async {
    final token = await _messaging.getToken();
    if (token != null && _authRepository != null) {
      await _authRepository!.unregisterDeviceToken(token);
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notification permission denied');
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push notification permission denied');
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}
