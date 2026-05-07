class Task {

  Task({
    this.id,
    required this.taskName,
    required this.type,
    this.taskDate,
    this.taskReminderDate,
    this.notes,
    this.employeeId,
    this.employeeName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse((value ?? '').toString());
    }

    return Task(
      id: parseInt(json['id']),
      taskName: (json['taskName'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      taskDate: json['taskDate']?.toString(),
      taskReminderDate: json['taskReminderDate']?.toString(),
      notes: json['notes'] as String?,
      employeeId: parseInt(json['employeeId']),
      employeeName: json['employeeName']?.toString(),
    );
  }
  final int? id;
  final String taskName;
  final String type;
  final String? taskDate;
  final String? taskReminderDate;
  final String? notes;
  final int? employeeId;
  final String? employeeName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskName': taskName,
      'type': type,
      'taskDate': taskDate,
      'taskReminderDate': taskReminderDate,
      'notes': notes,
      'employeeId': employeeId,
      'employeeName': employeeName,
    };
  }
}

class EmployeeItem {

  EmployeeItem({
    required this.id,
    this.usersId,
    this.fullName,
    this.email,
  });

  factory EmployeeItem.fromJson(Map<String, dynamic> json) {
    final identity = json['identity'] as Map<String, dynamic>?;
    return EmployeeItem(
      id: json['id'] as int,
      usersId: json['usersId'] as int?,
      fullName: identity?['fullName'] as String?,
      email: identity?['email'] as String?,
    );
  }
  final int id;
  final int? usersId;
  final String? fullName;
  final String? email;
}
