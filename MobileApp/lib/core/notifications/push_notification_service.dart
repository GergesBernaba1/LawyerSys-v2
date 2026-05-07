import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:qadaya_lawyersys/core/notifications/notification_handler.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/features/authentication/repositories/auth_repository.dart';
import 'package:qadaya_lawyersys/features/notifications/models/notification.dart';
import 'package:qadaya_lawyersys/features/notifications/repositories/notifications_repository.dart';

class PushNotificationService {

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();
  static final PushNotificationService _instance = PushNotificationService._internal();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  FirebaseMessaging? _messaging;
  AuthRepository? _authRepository;
  NotificationsRepository? _notificationsRepository;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  FirebaseMessaging get _firebaseMessaging {
    return _messaging ??= FirebaseMessaging.instance;
  }

  void configure(AuthRepository authRepository, {NotificationsRepository? notificationsRepository}) {
    _authRepository = authRepository;
    _notificationsRepository = notificationsRepository;
  }

  Future<void> init() async {
    // Cancel any previous subscriptions before re-subscribing.
    await _cancelSubscriptions();

    try {
      if (Platform.isIOS || Platform.isAndroid) {
        await _requestPermission();
      }

      final token = await _firebaseMessaging.getToken();
      if (token != null && token.isNotEmpty && _authRepository != null) {
        await _authRepository!.registerDeviceToken(token, platform: Platform.operatingSystem);
      }

      _tokenRefreshSub = _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty && _authRepository != null) {
          await _authRepository!.registerDeviceToken(newToken, platform: Platform.operatingSystem);
        }
      });

      _onMessageSub = FirebaseMessaging.onMessage.listen((event) async {
        debugPrint('Foreground message: ${event.notification?.title} ${event.notification?.body}');
        await _persistNotification(event);
        NotificationHandler.onMessage(event);
      });

      _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((event) async {
        debugPrint('Notification opened-app payload: ${event.data}');
        await _persistNotification(event);
        NotificationHandler.onMessageOpened(event);
      });

      FirebaseMessaging.onBackgroundMessage(NotificationHandler.firebaseMessagingBackgroundHandler);
    } catch (e, st) {
      debugPrint('PushNotificationService.init failed: $e\n$st');
    }
  }

  Future<void> _cancelSubscriptions() async {
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    _tokenRefreshSub = null;
    _onMessageSub = null;
    _onMessageOpenedSub = null;
  }

  Future<void> disable() async {
    await _cancelSubscriptions();
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null && token.isNotEmpty && _authRepository != null) {
        await _authRepository!.unregisterDeviceToken(token);
      }
    } catch (e, st) {
      debugPrint('PushNotificationService.disable failed: $e\n$st');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      
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


