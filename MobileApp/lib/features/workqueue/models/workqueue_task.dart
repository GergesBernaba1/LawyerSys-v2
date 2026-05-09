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

    // Backend returns AdminTaskDto:
    //   { id, taskName, type, taskDate, taskReminderDate, notes, employeeId, employeeName }
    // We map those fields, with fallbacks for any future shape changes.
    return WorkqueueTask(
      id: parseInt(json['id']) ?? 0,
      title: (json['taskName'] ?? json['title'] ?? '').toString(),
      description: (json['notes'] ?? json['description'])?.toString(),
      // Backend has no status field — use 'type' as status proxy, default Pending.
      status: (json['type'] ?? json['status'] ?? 'Pending').toString(),
      priority: json['priority']?.toString(),
      // taskReminderDate is the due-date equivalent on the backend.
      dueDate: parseDate(json['taskReminderDate'] ?? json['dueDate']),
      caseCode: json['caseCode']?.toString(),
      assignedToName: (json['employeeName'] ?? json['assignedToName'])?.toString(),
      assignedToId: parseInt(json['employeeId'] ?? json['assignedToId']),
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
