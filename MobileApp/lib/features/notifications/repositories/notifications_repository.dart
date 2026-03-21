import 'dart:convert';

import '../../../core/storage/local_database.dart';
import '../models/notification.dart';

class NotificationsRepository {
  final LocalDatabase localDatabase;

  NotificationsRepository(this.localDatabase);

  Future<List<AppNotification>> getNotifications({String? tenantId, int limit = 100}) async {
    final rows = await localDatabase.getNotifications(tenantId: tenantId, limit: limit);
    return rows.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return AppNotification.fromJson(data);
    }).toList();
  }

  Future<void> addNotification(AppNotification notification, {String? tenantId}) async {
    await localDatabase.upsertNotification(notification.notificationId, notification.toJson(), tenantId: tenantId, isRead: false);
  }

  Future<void> markAsRead(String notificationId) async {
    await localDatabase.markNotificationAsRead(notificationId);
  }

  Future<void> clearNotifications() async {
    await localDatabase.clearAllNotifications();
  }
}
