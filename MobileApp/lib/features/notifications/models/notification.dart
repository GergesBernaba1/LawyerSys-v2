class AppNotification {

  AppNotification({
    required this.notificationId,
    required this.title,
    required this.message,
    this.isRead = false,
    this.category,
    this.route,
    this.timestamp,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        notificationId: json['notificationId']?.toString() ?? json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        category: json['category'] as String?,
        route: json['route'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString())
            : null,
      );
  final String notificationId;
  final String title;
  final String message;
  final bool isRead;
  final String? category;
  final String? route;
  final DateTime? timestamp;

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'title': title,
        'message': message,
        'isRead': isRead,
        'category': category,
        'route': route,
        'timestamp': timestamp?.toIso8601String(),
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        notificationId: notificationId,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        category: category,
        route: route,
        timestamp: timestamp,
      );
}
