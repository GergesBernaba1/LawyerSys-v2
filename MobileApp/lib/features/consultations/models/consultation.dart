class ConsultationModel {
  final int id;
  final String tenantId;
  final String subject;
  final String details;
  final String status; // 'Pending', 'InProgress', 'Completed', 'Cancelled'
  final DateTime consultationDate;
  final String? customerId;
  final String? customerFullName;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final String? notes;
  final DateTime? lastSyncedAt;
  final bool isDirty;

  ConsultationModel({
    required this.id,
    required this.tenantId,
    required this.subject,
    required this.details,
    required this.status,
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
        id: json['id'] ?? 0,
        tenantId: json['tenantId']?.toString() ?? '',
        subject: json['subject']?.toString() ?? '',
        details: json['details']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Pending',
        consultationDate: json['consultationDate'] != null
            ? DateTime.tryParse(json['consultationDate'].toString()) ?? DateTime.now()
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'subject': subject,
        'details': details,
        'status': status,
        'consultationDate': consultationDate.toIso8601String(),
        'customerId': customerId,
        'customerFullName': customerFullName,
        'assignedEmployeeId': assignedEmployeeId,
        'assignedEmployeeName': assignedEmployeeName,
        'notes': notes,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'isDirty': isDirty,
      };
}
