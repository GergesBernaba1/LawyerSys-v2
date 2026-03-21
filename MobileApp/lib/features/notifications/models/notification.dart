class AppNotification {
  final String notificationId;
  final String title;
  final String message;

  AppNotification({required this.notificationId, required this.title, required this.message});

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        notificationId: json['notificationId'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
      );

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'title': title,
        'message': message,
      };
}
