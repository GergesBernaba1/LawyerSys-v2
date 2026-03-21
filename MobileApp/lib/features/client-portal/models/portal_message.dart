class PortalMessageModel {
  final String messageId;
  final String subject;
  final String body;
  final String from;
  final DateTime sentAt;
  final bool isRead;

  PortalMessageModel({
    required this.messageId,
    required this.subject,
    required this.body,
    required this.from,
    required this.sentAt,
    required this.isRead,
  });

  factory PortalMessageModel.fromJson(Map<String, dynamic> json) => PortalMessageModel(
        messageId: json['messageId']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        from: json['from']?.toString() ?? '',
        sentAt: json['sentAt'] != null ? DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now() : DateTime.now(),
        isRead: json['isRead'] == true || json['isRead']?.toString().toLowerCase() == 'true',
      );

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'subject': subject,
        'body': body,
        'from': from,
        'sentAt': sentAt.toIso8601String(),
        'isRead': isRead,
      };
}
