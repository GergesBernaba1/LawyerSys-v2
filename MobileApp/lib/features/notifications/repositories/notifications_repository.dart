import 'dart:convert';

import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/storage/local_database.dart';
import 'package:qadaya_lawyersys/features/notifications/models/notification.dart';

class NotificationsRepository {

  NotificationsRepository(this.localDatabase, [this.apiClient]);
  final LocalDatabase localDatabase;
  final ApiClient? apiClient;

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['Items'];
      if (items is List<dynamic>) return items;
    }
    return const [];
  }

  Future<List<AppNotification>> getNotifications(
      {String? tenantId, int limit = 100,}) async {
    if (apiClient != null) {
      try {
        final response = await apiClient!.get(
          '/api/notifications',
          queryParameters: {'page': 1, 'pageSize': limit},
        );

        for (final item in _asList(response.data)) {
          final map = Map<String, dynamic>.from(item as Map);
          final notification = AppNotification(
            notificationId: (map['id'] ?? map['Id'] ?? '').toString(),
            title: (map['title'] ?? map['Title'] ?? '').toString(),
            message: (map['message'] ?? map['Message'] ?? '').toString(),
            isRead: (map['isRead'] ?? map['IsRead'] ?? false) == true,
            category: (map['category'] ?? map['Category'])?.toString(),
            route: (map['route'] ?? map['Route'])?.toString(),
            timestamp: DateTime.tryParse(
              (map['timestamp'] ?? map['Timestamp'] ?? '').toString(),
            ),
          );
          await localDatabase.upsertNotification(
            notification.notificationId,
            notification.toJson(),
            tenantId: tenantId,
            isRead: notification.isRead,
          );
        }
      } catch (_) {
        // fall back to local cache
      }
    }

    final rows =
        await localDatabase.getNotifications(tenantId: tenantId, limit: limit);
    return rows.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return AppNotification.fromJson(data);
    }).toList();
  }

  Future<void> addNotification(AppNotification notification,
      {String? tenantId,}) async {
    await localDatabase.upsertNotification(
        notification.notificationId, notification.toJson(),
        tenantId: tenantId,);
  }

  Future<void> markAsRead(String notificationId) async {
    if (apiClient != null && int.tryParse(notificationId) != null) {
      try {
        await apiClient!.post('/api/notifications/$notificationId/read');
      } catch (_) {
        // continue and still mark local cache
      }
    }
    await localDatabase.markNotificationAsRead(notificationId);
  }

  Future<void> clearNotifications() async {
    await localDatabase.clearAllNotifications();
  }
}
