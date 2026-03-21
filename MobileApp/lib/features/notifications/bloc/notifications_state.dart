import '../models/notification.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;
  NotificationsLoaded(this.notifications);
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}
