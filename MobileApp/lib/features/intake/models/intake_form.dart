class IntakeForm {
  final int id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? nationalId;
  final String subject;
  final String? description;
  final String? desiredCaseType;
  final String status;
  final String? qualificationNotes;
  final bool conflictChecked;
  final bool hasConflict;
  final String? conflictDetails;
  final int? assignedEmployeeId;
  final String? assignedEmployeeName;
  final DateTime? nextFollowUpAt;
  final DateTime? assignedAt;
  final int? convertedCustomerId;
  final int? convertedCaseCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  IntakeForm({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.nationalId,
    required this.subject,
    this.description,
    this.desiredCaseType,
    required this.status,
    this.qualificationNotes,
    required this.conflictChecked,
    required this.hasConflict,
    this.conflictDetails,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.nextFollowUpAt,
    this.assignedAt,
    this.convertedCustomerId,
    this.convertedCaseCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IntakeForm.fromJson(Map<String, dynamic> json) => IntakeForm(
        id: json['id'] as int? ?? 0,
        fullName: json['fullName']?.toString() ?? '',
        email: json['email']?.toString(),
        phoneNumber: json['phoneNumber']?.toString(),
        nationalId: json['nationalId']?.toString(),
        subject: json['subject']?.toString() ?? '',
        description: json['description']?.toString(),
        desiredCaseType: json['desiredCaseType']?.toString(),
        status: json['status']?.toString() ?? 'New',
        qualificationNotes: json['qualificationNotes']?.toString(),
        conflictChecked: json['conflictChecked'] as bool? ?? false,
        hasConflict: json['hasConflict'] as bool? ?? false,
        conflictDetails: json['conflictDetails']?.toString(),
        assignedEmployeeId: json['assignedEmployeeId'] as int?,
        assignedEmployeeName: json['assignedEmployeeName']?.toString(),
        nextFollowUpAt: json['nextFollowUpAt'] != null
            ? DateTime.tryParse(json['nextFollowUpAt'].toString())
            : null,
        assignedAt: json['assignedAt'] != null
            ? DateTime.tryParse(json['assignedAt'].toString())
            : null,
        convertedCustomerId: json['convertedCustomerId'] as int?,
        convertedCaseCode: json['convertedCaseCode'] as int?,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'nationalId': nationalId,
        'subject': subject,
        'description': description,
        'desiredCaseType': desiredCaseType,
        'status': status,
        'qualificationNotes': qualificationNotes,
        'conflictChecked': conflictChecked,
        'hasConflict': hasConflict,
        'conflictDetails': conflictDetails,
        'assignedEmployeeId': assignedEmployeeId,
        'assignedEmployeeName': assignedEmployeeName,
        'nextFollowUpAt': nextFollowUpAt?.toIso8601String(),
        'assignedAt': assignedAt?.toIso8601String(),
        'convertedCustomerId': convertedCustomerId,
        'convertedCaseCode': convertedCaseCode,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isConverted => status == 'Converted';
  bool get isQualified => status == 'Qualified';
  bool get isRejected => status == 'Rejected';
  bool get isNew => status == 'New';
}

class IntakeAssignmentOption {
  final int employeeId;
  final String name;

  IntakeAssignmentOption({required this.employeeId, required this.name});

  factory IntakeAssignmentOption.fromJson(Map<String, dynamic> json) =>
      IntakeAssignmentOption(
        employeeId: json['employeeId'] as int? ?? 0,
        name: json['name']?.toString() ?? '',
      );
}

class IntakeConflictCheck {
  final bool hasConflict;
  final String details;

  IntakeConflictCheck({required this.hasConflict, required this.details});

  factory IntakeConflictCheck.fromJson(Map<String, dynamic> json) =>
      IntakeConflictCheck(
        hasConflict: json['hasConflict'] as bool? ?? false,
        details: json['details']?.toString() ?? '',
      );
}
