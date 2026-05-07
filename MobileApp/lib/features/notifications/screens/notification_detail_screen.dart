import 'package:flutter/material.dart';
import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/notifications/models/notification.dart';

class NotificationDetailScreen extends StatelessWidget {

  const NotificationDetailScreen({super.key, required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.notification)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(notification.message),
          ],
        ),
      ),
    );
  }
}
