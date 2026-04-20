class CaseRelation {
  final int id;
  final int caseId;
  final int relatedCaseId;
  final String relationType; // e.g. "Related", "Appeal", "Consolidated"
  final String? relatedCaseNumber; // display number of related case
  final String? notes;

  CaseRelation({
    required this.id,
    required this.caseId,
    required this.relatedCaseId,
    required this.relationType,
    this.relatedCaseNumber,
    this.notes,
  });

  factory CaseRelation.fromJson(Map<String, dynamic> json) => CaseRelation(
        id: json['id'] as int? ?? 0,
        caseId: json['caseId'] as int? ?? 0,
        relatedCaseId: json['relatedCaseId'] as int? ?? 0,
        relationType: json['relationType']?.toString() ?? '',
        relatedCaseNumber: json['relatedCaseNumber']?.toString(),
        notes: json['notes']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'relatedCaseId': relatedCaseId,
        'relationType': relationType,
        'relatedCaseNumber': relatedCaseNumber,
        'notes': notes,
      };
}
