import 'package:qadaya_lawyersys/features/notifications/models/notification.dart';

abstract class NotificationsEvent {}

class LoadNotifications extends NotificationsEvent {}

class NewNotificationReceived extends NotificationsEvent {
  NewNotificationReceived(this.notification);
  final AppNotification notification;
}

class MarkNotificationRead extends NotificationsEvent {
  MarkNotificationRead(this.notificationId);
  final String notificationId;
}

class ClearNotifications extends NotificationsEvent {}
