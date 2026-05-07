class ConsultationModel {

  ConsultationModel({
    required this.id,
    required this.tenantId,
    required this.subject,
    required this.details,
    required this.status,
    this.type = '',
    this.feedback,
    required this.consultationDate,
    this.customerId,
    this.customerFullName,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.notes,
    this.lastSyncedAt,
    this.isDirty = false,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) => ConsultationModel(
        id: _asInt(json['id'] ?? json['Id']),
        tenantId: json['tenantId']?.toString() ?? '',
        subject: (json['subject'] ?? json['Subject'] ?? '').toString(),
        details: (json['details'] ?? json['description'] ?? json['Description'] ?? '').toString(),
        status: (json['status'] ?? json['consultionState'] ?? json['ConsultionState'] ?? 'Pending').toString(),
        type: (json['type'] ?? json['Type'] ?? '').toString(),
        feedback: (json['feedback'] ?? json['Feedback'])?.toString(),
        consultationDate: (json['consultationDate'] ?? json['dateTime'] ?? json['DateTime']) != null
            ? DateTime.tryParse((json['consultationDate'] ?? json['dateTime'] ?? json['DateTime']).toString()) ?? DateTime.now()
            : DateTime.now(),
        customerId: json['customerId']?.toString(),
        customerFullName: json['customerFullName']?.toString(),
        assignedEmployeeId: json['assignedEmployeeId']?.toString(),
        assignedEmployeeName: json['assignedEmployeeName']?.toString(),
        notes: json['notes']?.toString(),
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.tryParse(json['lastSyncedAt'].toString())
            : null,
        isDirty: json['isDirty'] == true,
      );
  final int id;
  final String tenantId;
  final String subject;
  final String details;
  final String status;
  final String type;
  final String? feedback;
  final DateTime consultationDate;
  final String? customerId;
  final String? customerFullName;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final String? notes;
  final DateTime? lastSyncedAt;
  final bool isDirty;

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'subject': subject,
        // Backend DTO expects these names.
        'consultionState': status,
        'type': type,
        'description': details,
        'feedback': feedback,
        'dateTime': consultationDate.toIso8601String(),
        'customerId': customerId,
        'customerFullName': customerFullName,
        'assignedEmployeeId': assignedEmployeeId,
        'assignedEmployeeName': assignedEmployeeName,
        'notes': notes,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'isDirty': isDirty,
      };
}
