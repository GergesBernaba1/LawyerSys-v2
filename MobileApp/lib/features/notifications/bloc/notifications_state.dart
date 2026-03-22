import '../models/notification.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;
  NotificationsLoaded(this.notifications, {this.unreadCount = 0});
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}
