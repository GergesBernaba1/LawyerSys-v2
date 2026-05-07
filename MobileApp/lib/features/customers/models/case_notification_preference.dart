class CaseNotificationPreference {

  CaseNotificationPreference({
    required this.caseCode,
    required this.notificationsEnabled,
  });

  factory CaseNotificationPreference.fromJson(Map<String, dynamic> json) {
    return CaseNotificationPreference(
      caseCode: (json['caseCode'] as int?) ?? 0,
      notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
    );
  }
  final int caseCode;
  final bool notificationsEnabled;

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
