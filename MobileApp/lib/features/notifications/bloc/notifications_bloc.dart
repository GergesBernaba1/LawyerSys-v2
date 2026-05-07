import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/notifications/bloc/notifications_event.dart';
import 'package:qadaya_lawyersys/features/notifications/bloc/notifications_state.dart';
import 'package:qadaya_lawyersys/features/notifications/repositories/notifications_repository.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {

  NotificationsBloc({required this.notificationsRepository}) : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<NewNotificationReceived>(_onNewNotificationReceived);
    on<MarkNotificationRead>(_onMarkNotificationRead);
    on<ClearNotifications>(_onClearNotifications);
  }
  final NotificationsRepository notificationsRepository;

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<NotificationsState> emit) async {
    emit(NotificationsLoading());
    try {
      final list = await notificationsRepository.getNotifications();
      final unread = list.where((n) => !n.isRead).length;
      emit(NotificationsLoaded(list, unreadCount: unread));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onNewNotificationReceived(NewNotificationReceived event, Emitter<NotificationsState> emit) async {
    try {
      await notificationsRepository.addNotification(event.notification);
      final list = await notificationsRepository.getNotifications();
      final unread = list.where((n) => !n.isRead).length;
      emit(NotificationsLoaded(list, unreadCount: unread));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onMarkNotificationRead(MarkNotificationRead event, Emitter<NotificationsState> emit) async {
    try {
      await notificationsRepository.markAsRead(event.notificationId);
      final list = await notificationsRepository.getNotifications();
      final unread = list.where((n) => !n.isRead).length;
      emit(NotificationsLoaded(list, unreadCount: unread));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onClearNotifications(ClearNotifications event, Emitter<NotificationsState> emit) async {
    try {
      await notificationsRepository.clearNotifications();
      emit(NotificationsLoaded([]));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }
}
