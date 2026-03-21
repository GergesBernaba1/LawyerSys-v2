class Task {
  final int? id;
  final String taskName;
  final String type;
  final String? taskDate;
  final String? taskReminderDate;
  final String? notes;
  final int? employeeId;
  final String? employeeName;

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
    return Task(
      id: json['id'] as int?,
      taskName: json['taskName'] as String,
      type: json['type'] as String,
      taskDate: json['taskDate'] as String?,
      taskReminderDate: json['taskReminderDate'] as String?,
      notes: json['notes'] as String?,
      employeeId: json['employeeId'] as int?,
      employeeName: json['employeeName'] as String?,
    );
  }

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
  final int id;
  final int? usersId;
  final String? fullName;
  final String? email;

  EmployeeItem({
    required this.id,
    this.usersId,
    this.fullName,
    this.email,
  });

  factory EmployeeItem.fromJson(Map<String, dynamic> json) {
    return EmployeeItem(
      id: json['id'] as int,
      usersId: json['usersId'] as int?,
      fullName: json['identity']?['fullName'] as String?,
      email: json['identity']?['email'] as String?,
    );
  }
}