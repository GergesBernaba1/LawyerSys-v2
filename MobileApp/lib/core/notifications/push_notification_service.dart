import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../core/storage/local_database.dart';
import '../../features/authentication/repositories/auth_repository.dart';
import '../../features/notifications/models/notification.dart';
import '../../features/notifications/repositories/notifications_repository.dart';
import 'notification_handler.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  AuthRepository? _authRepository;
  NotificationsRepository? _notificationsRepository;

  void configure(AuthRepository authRepository, {NotificationsRepository? notificationsRepository}) {
    _authRepository = authRepository;
    _notificationsRepository = notificationsRepository;
  }

  Future<void> init() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        await _requestPermission();
      }

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty && _authRepository != null) {
        await _authRepository!.registerDeviceToken(token, platform: Platform.operatingSystem);
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty && _authRepository != null) {
          await _authRepository!.registerDeviceToken(newToken, platform: Platform.operatingSystem);
        }
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage event) async {
        debugPrint('Foreground message: ${event.notification?.title} ${event.notification?.body}');
        await _persistNotification(event);
        NotificationHandler.onMessage(event);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage event) async {
        debugPrint('Notification opened-app payload: ${event.data}');
        await _persistNotification(event);
        NotificationHandler.onMessageOpened(event);
      });

      FirebaseMessaging.onBackgroundMessage(NotificationHandler.firebaseMessagingBackgroundHandler);
    } catch (e, st) {
      debugPrint('PushNotificationService.init failed: $e\n$st');
    }
  }

  Future<void> disable() async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty && _authRepository != null) {
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

  Future<void> _persistNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Notification';
    final body = message.notification?.body ?? message.data['body']?.toString() ?? '';
    final notificationId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final repo = _notificationsRepository ?? NotificationsRepository(LocalDatabase.instance);

    try {
      await repo.addNotification(AppNotification(notificationId: notificationId, title: title, message: body));
    } catch (e, st) {
      debugPrint('Failed to store notification: $e\n$st');
    }
  }
}

