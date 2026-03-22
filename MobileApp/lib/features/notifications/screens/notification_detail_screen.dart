import 'package:flutter/material.dart';

import '../models/notification.dart';

class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')), 
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
