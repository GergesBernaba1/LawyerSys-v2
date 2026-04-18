class SitingModel {
  final int id;
  final String? caseCode;
  final String? caseTitle;
  final int? courtId;
  final String? courtName;
  final DateTime sitingDate;
  final String? notes;
  final String? status;

  SitingModel({
    required this.id,
    this.caseCode,
    this.caseTitle,
    this.courtId,
    this.courtName,
    required this.sitingDate,
    this.notes,
    this.status,
  });

  factory SitingModel.fromJson(Map<String, dynamic> json) {
    return SitingModel(
      id: (json['id'] as num).toInt(),
      caseCode: json['caseCode']?.toString(),
      caseTitle: json['caseTitle']?.toString(),
      courtId: json['courtId'] != null ? (json['courtId'] as num).toInt() : null,
      courtName: json['courtName']?.toString(),
      sitingDate: DateTime.parse(json['sitingDate'].toString()),
      notes: json['notes']?.toString(),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (caseCode != null) 'caseCode': caseCode,
      if (caseTitle != null) 'caseTitle': caseTitle,
      if (courtId != null) 'courtId': courtId,
      if (courtName != null) 'courtName': courtName,
      'sitingDate': sitingDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
    };
  }
}
