import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:qadaya_lawyersys/core/notifications/push_notification_service.dart';

class NotificationHandler {
  static void onMessage(RemoteMessage message) {
    // Add any in-app banner handling (e.g., in-app Toast) if needed.
    debugPrint('onMessage handler: ${message.messageId}, data=${message.data}');
  }

  static Future<void> onMessageOpened(RemoteMessage message) async {
    debugPrint('onMessageOpened handler: ${message.messageId}, data=${message.data}');

    final route = message.data['route']?.toString().trim() ?? message.data['Route']?.toString().trim();
    if (route != null && route.isNotEmpty) {
      _navigate(route);
      return;
    }

    final entityType = message.data['relatedEntityType']?.toString().trim();
    final entityId = message.data['relatedEntityId']?.toString().trim();

    if (entityType != null && entityType.isNotEmpty) {
      final fallbackRoute = _routeForEntity(entityType, entityId);
      if (fallbackRoute != null) {
        _navigate(fallbackRoute);
      }
    }
  }

  static void _navigate(String route) {
    final navState = PushNotificationService.navigatorKey.currentState;
    if (navState == null) {
      debugPrint('NavigatorState unavailable; cannot route to $route');
      return;
    }

    try {
      if (route.startsWith('/')) {
        navState.pushNamed(route);
      } else {
        navState.pushNamed('/$route');
      }
    } catch (error) {
      debugPrint('Failed to navigate to route $route: $error');
    }
  }

  static String? _routeForEntity(String entityType, String? entityId) {
    switch (entityType.toLowerCase()) {
      case 'case':
        return '/cases';
      case 'hearing':
        return '/hearings';
      case 'customer':
        return '/customers';
      case 'task':
        return '/tasks';
      case 'document':
        return '/documents';
      case 'invoice':
      case 'payment':
        return '/billing';
      case 'employee':
        return '/employees';
      case 'consultation':
        return '/consultations';
      default:
        return '/notifications';
    }
  }

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('Handling a background message in NotificationHandler: ${message.messageId}');
    // Background handler cannot navigate, but can store analytics or update local data if required
  }
}
