class Hearing {
  final String hearingId;
  final String tenantId;
  final DateTime hearingDate;
  final String caseId;
  final String caseNumber;
  final String judgeName;
  final String courtId;
  final String courtName;
  final String courtLocation;
  final String? hearingNotificationDetails;
  final String? notes;
  final DateTime? lastSyncedAt;
  final bool isDirty;

  Hearing({
    required this.hearingId,
    required this.tenantId,
    required this.hearingDate,
    required this.caseId,
    required this.caseNumber,
    required this.judgeName,
    required this.courtId,
    required this.courtName,
    required this.courtLocation,
    this.hearingNotificationDetails,
    this.notes,
    this.lastSyncedAt,
    this.isDirty = false,
  });

  factory Hearing.fromJson(Map<String, dynamic> json) => Hearing(
        hearingId: json['hearingId'] as String,
        tenantId: json['tenantId'] as String? ?? '',
        hearingDate: DateTime.tryParse(json['hearingDate'] as String? ?? '') ?? DateTime.now(),
        caseId: json['caseId'] as String? ?? '',
        caseNumber: json['caseNumber'] as String? ?? '',
        judgeName: json['judgeName'] as String? ?? '',
        courtId: json['courtId'] as String? ?? '',
        courtName: json['courtName'] as String? ?? '',
        courtLocation: json['courtLocation'] as String? ?? '',
        hearingNotificationDetails: json['hearingNotificationDetails'] as String?,
        notes: json['notes'] as String?,
        lastSyncedAt: json['lastSyncedAt'] != null ? DateTime.tryParse(json['lastSyncedAt'] as String) : null,
        isDirty: json['isDirty'] == true || json['isDirty'] == 1,
      );

  Map<String, dynamic> toJson() => {
        'hearingId': hearingId,
        'tenantId': tenantId,
        'hearingDate': hearingDate.toIso8601String(),
        'caseId': caseId,
        'caseNumber': caseNumber,
        'judgeName': judgeName,
        'courtId': courtId,
        'courtName': courtName,
        'courtLocation': courtLocation,
        'hearingNotificationDetails': hearingNotificationDetails,
        'notes': notes,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'isDirty': isDirty,
      };
}
