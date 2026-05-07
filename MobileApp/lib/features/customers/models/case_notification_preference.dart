class CaseNotificationPreference {
  final int caseCode;
  final bool notificationsEnabled;

  CaseNotificationPreference({
    required this.caseCode,
    required this.notificationsEnabled,
  });

  factory CaseNotificationPreference.fromJson(Map<String, dynamic> json) {
    return CaseNotificationPreference(
      caseCode: json['caseCode'] ?? 0,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'caseCode': caseCode,
        'notificationsEnabled': notificationsEnabled,
      };

  CaseNotificationPreference copyWith({
    int? caseCode,
    bool? notificationsEnabled,
  }) {
    return CaseNotificationPreference(
      caseCode: caseCode ?? this.caseCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
