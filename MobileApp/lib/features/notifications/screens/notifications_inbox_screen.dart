import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/notifications/bloc/notifications_bloc.dart';
import 'package:qadaya_lawyersys/features/notifications/bloc/notifications_event.dart';
import 'package:qadaya_lawyersys/features/notifications/bloc/notifications_state.dart';
import 'package:qadaya_lawyersys/features/notifications/screens/notification_detail_screen.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key});

  @override
  State<NotificationsInboxScreen> createState() => _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(LoadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final localizer = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizer.notifications),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: localizer.clearAll,
            onPressed: () {
              context.read<NotificationsBloc>().add(ClearNotifications());
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsError) {
            return Center(child: Text('${localizer.error}: ${state.message}'));
          }
          if (state is NotificationsLoaded) {
            final notifications = state.notifications;
            if (notifications.isEmpty) {
              return Center(child: Text(localizer.noData));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NotificationsBloc>().add(LoadNotifications());
              },
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return ListTile(
                    title: Text(notif.title),
                    subtitle: Text(notif.message),
                    trailing: IconButton(
                      icon: const Icon(Icons.mark_email_read),
                      onPressed: () {
                        context.read<NotificationsBloc>().add(MarkNotificationRead(notif.notificationId));
                      },
                    ),
                    onTap: () {
                      context.read<NotificationsBloc>().add(MarkNotificationRead(notif.notificationId));
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => NotificationDetailScreen(notification: notif)),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
