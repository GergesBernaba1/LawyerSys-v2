class CaseModel {

  CaseModel({
    required this.id,
    required this.code,
    required this.invitionsStatment,
    required this.invitionType,
    this.invitionDate,
    required this.totalAmount,
    required this.notes,
    required this.status,
    this.tenantId = '',
    required this.assignedEmployees,
    this.lastSyncedAt,
    this.isDirty = false,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
        id: _asInt(json['id'] ?? json['Id']),
        code: _asInt(
            json['code'] ?? json['Code'] ?? json['caseId'] ?? json['caseCode'],),
        invitionsStatment:
            (json['invitionsStatment'] ?? json['InvitionsStatment'] ?? '')
                .toString(),
        invitionType:
            (json['invitionType'] ?? json['InvitionType'] ?? '').toString(),
        invitionDate: _parseDate(
            json['invitionDate'] ?? json['InvitionDate'] ?? json['filingDate'],),
        totalAmount: _asInt(json['totalAmount'] ?? json['TotalAmount']),
        notes: (json['notes'] ?? json['Notes'] ?? '').toString(),
        status: _asInt(json['status'] ?? json['Status']),
        tenantId: (json['tenantId'] ?? json['TenantId'] ?? '').toString(),
        assignedEmployees: (json['assignedEmployees'] as List<dynamic>?)
                ?.map((e) =>
                    EmployeeAssignment.fromJson(e as Map<String, dynamic>),)
                .toList() ??
            [],
        lastSyncedAt: _parseDate(json['lastSyncedAt']),
        isDirty: (json['isDirty'] as bool?) ?? false,
      );
  final int id;
  final int code;
  final String invitionsStatment;
  final String invitionType;
  final DateTime? invitionDate;
  final int totalAmount;
  final String notes;
  final int status;
  final String tenantId;
  final List<EmployeeAssignment> assignedEmployees;
  final DateTime? lastSyncedAt;
  final bool isDirty;

  // Backward-compatible aliases for existing UI code.
  String get caseId => code.toString();
  String get caseNumber => code.toString();
  String get caseStatus => statusLabel;
  String get caseType => invitionType;
  DateTime? get filingDate => invitionDate;
  DateTime? get closingDate => null;
  String get customerId => '';
  String get customerFullName => '';
  String get courtId => '';
  String get courtName => '';

  String get statusLabel {
    switch (status) {
      case 0:
        return 'New';
      case 1:
        return 'In Progress';
      case 2:
        return 'Awaiting Hearing';
      case 3:
        return 'Closed';
      case 4:
        return 'Won';
      case 5:
        return 'Lost';
      default:
        return 'Unknown';
    }
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'invitionsStatment': invitionsStatment,
        'invitionType': invitionType,
        'invitionDate': invitionDate?.toIso8601String(),
        'totalAmount': totalAmount,
        'notes': notes,
        'status': status,
        'tenantId': tenantId,
        'assignedEmployees': assignedEmployees.map((e) => e.toJson()).toList(),
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'isDirty': isDirty,
      };
}

class EmployeeAssignment {

  EmployeeAssignment(
      {required this.employeeId,
      required this.employeeName,
      required this.role,});

  factory EmployeeAssignment.fromJson(Map<String, dynamic> json) =>
      EmployeeAssignment(
        employeeId: (json['employeeId'] ?? '').toString(),
        employeeName: (json['employeeName'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
      );
  final String employeeId;
  final String employeeName;
  final String role;

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'role': role,
      };
}
