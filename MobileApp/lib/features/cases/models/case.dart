class CaseModel {
  final String caseId;
  final String tenantId;
  final String caseNumber;
  final String invitationType;
  final String caseStatus;
  final String caseType;
  final DateTime? filingDate;
  final DateTime? closingDate;
  final String customerId;
  final String customerFullName;
  final String courtId;
  final String courtName;
  final List<EmployeeAssignment> assignedEmployees;
  final DateTime? lastSyncedAt;
  final bool isDirty;

  CaseModel({
    required this.caseId,
    required this.tenantId,
    required this.caseNumber,
    required this.invitationType,
    required this.caseStatus,
    required this.caseType,
    this.filingDate,
    this.closingDate,
    required this.customerId,
    required this.customerFullName,
    required this.courtId,
    required this.courtName,
    required this.assignedEmployees,
    this.lastSyncedAt,
    this.isDirty = false,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
    caseId: json['caseId'] ?? '',
    tenantId: json['tenantId'] ?? '',
    caseNumber: json['caseNumber'] ?? '',
    invitationType: json['invitationType'] ?? '',
    caseStatus: json['caseStatus'] ?? '',
    caseType: json['caseType'] ?? '',
    filingDate: json['filingDate'] != null ? DateTime.tryParse(json['filingDate']) : null,
    closingDate: json['closingDate'] != null ? DateTime.tryParse(json['closingDate']) : null,
    customerId: json['customerId'] ?? '',
    customerFullName: json['customerFullName'] ?? '',
    courtId: json['courtId'] ?? '',
    courtName: json['courtName'] ?? '',
    assignedEmployees: (json['assignedEmployees'] as List<dynamic>?)?.map((e) => EmployeeAssignment.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    lastSyncedAt: json['lastSyncedAt'] != null ? DateTime.tryParse(json['lastSyncedAt']) : null,
    isDirty: json['isDirty'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'caseId': caseId,
    'tenantId': tenantId,
    'caseNumber': caseNumber,
    'invitationType': invitationType,
    'caseStatus': caseStatus,
    'caseType': caseType,
    'filingDate': filingDate?.toIso8601String(),
    'closingDate': closingDate?.toIso8601String(),
    'customerId': customerId,
    'customerFullName': customerFullName,
    'courtId': courtId,
    'courtName': courtName,
    'assignedEmployees': assignedEmployees.map((e) => e.toJson()).toList(),
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'isDirty': isDirty,
  };
}

class EmployeeAssignment {
  final String employeeId;
  final String employeeName;
  final String role;

  EmployeeAssignment({required this.employeeId, required this.employeeName, required this.role});

  factory EmployeeAssignment.fromJson(Map<String, dynamic> json) => EmployeeAssignment(
    employeeId: json['employeeId'] ?? '',
    employeeName: json['employeeName'] ?? '',
    role: json['role'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId,
    'employeeName': employeeName,
    'role': role,
  };
}
