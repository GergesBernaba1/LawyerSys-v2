class AuditLog {
  final int id;
  final String action;
  final String entityName;
  final String? entityId;
  final String? performedBy;
  final DateTime performedAt;
  final String? changes;

  AuditLog({
    required this.id,
    required this.action,
    required this.entityName,
    this.entityId,
    this.performedBy,
    required this.performedAt,
    this.changes,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse((v ?? '0').toString()) ?? 0;
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return AuditLog(
      id: parseInt(json['id']),
      action: (json['action'] ?? '').toString(),
      entityName: (json['entityName'] ?? '').toString(),
      entityId: json['entityId']?.toString(),
      performedBy: json['performedBy']?.toString(),
      performedAt: parseDate(json['performedAt']),
      changes: json['changes']?.toString(),
    );
  }
}
