import '../models/notification.dart';

abstract class NotificationsEvent {}

class LoadNotifications extends NotificationsEvent {}

class NewNotificationReceived extends NotificationsEvent {
  final AppNotification notification;
  NewNotificationReceived(this.notification);
}

class MarkNotificationRead extends NotificationsEvent {
  final String notificationId;
  MarkNotificationRead(this.notificationId);
}

class ClearNotifications extends NotificationsEvent {}
