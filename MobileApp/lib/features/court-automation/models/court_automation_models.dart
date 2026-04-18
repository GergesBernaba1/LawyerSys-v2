class AutomationPack {
  final String packKey;
  final String name;
  final String? description;
  final String? category;

  AutomationPack({
    required this.packKey,
    required this.name,
    this.description,
    this.category,
  });

  factory AutomationPack.fromJson(Map<String, dynamic> json) {
    return AutomationPack(
      packKey: json['packKey'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
    );
  }
}

class DeadlineItem {
  final String label;
  final String? deadline;
  final String? description;

  DeadlineItem({
    required this.label,
    this.deadline,
    this.description,
  });

  factory DeadlineItem.fromJson(Map<String, dynamic> json) {
    return DeadlineItem(
      label: json['label'] as String,
      deadline: json['deadline'] as String?,
      description: json['description'] as String?,
    );
  }
}

class FilingSubmission {
  final String submissionId;
  final String caseCode;
  final String packKey;
  final String status;
  final DateTime submittedAt;

  FilingSubmission({
    required this.submissionId,
    required this.caseCode,
    required this.packKey,
    required this.status,
    required this.submittedAt,
  });

  factory FilingSubmission.fromJson(Map<String, dynamic> json) {
    return FilingSubmission(
      submissionId: json['submissionId'] as String,
      caseCode: json['caseCode'] as String,
      packKey: json['packKey'] as String,
      status: json['status'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
    );
  }
}
