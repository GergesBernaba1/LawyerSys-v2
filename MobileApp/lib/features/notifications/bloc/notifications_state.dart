import 'package:qadaya_lawyersys/features/notifications/models/notification.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  NotificationsLoaded(this.notifications, {this.unreadCount = 0});
  final List<AppNotification> notifications;
  final int unreadCount;
}

class NotificationsError extends NotificationsState {
  NotificationsError(this.message);
  final String message;
}
