class WorkqueueTask {

  WorkqueueTask({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.priority,
    this.dueDate,
    this.caseCode,
    this.assignedToName,
    this.assignedToId,
  });

  factory WorkqueueTask.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse((value ?? '').toString());
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return WorkqueueTask(
      id: parseInt(json['id']) ?? 0,
      title: (json['title'] ?? json['taskName'] ?? '').toString(),
      description: json['description']?.toString(),
      status: (json['status'] ?? 'Pending').toString(),
      priority: json['priority']?.toString(),
      dueDate: parseDate(json['dueDate']),
      caseCode: json['caseCode']?.toString(),
      assignedToName: json['assignedToName']?.toString(),
      assignedToId: parseInt(json['assignedToId']),
    );
  }
  final int id;
  final String title;
  final String? description;
  final String status; // Pending, InProgress, Completed, Cancelled
  final String? priority; // Low, Medium, High
  final DateTime? dueDate;
  final String? caseCode;
  final String? assignedToName;
  final int? assignedToId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'caseCode': caseCode,
      'assignedToName': assignedToName,
      'assignedToId': assignedToId,
    };
  }
}
