class TimeEntry {
  final int? id;
  final int? caseCode;
  final int? customerId;
  final String workType;
  final String? description;
  final String status;
  final String? startedAt;
  final String? endedAt;
  final int? durationMinutes;
  final double? suggestedAmount;

  TimeEntry({
    this.id,
    this.caseCode,
    this.customerId,
    required this.workType,
    this.description,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.suggestedAmount,
  });

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'] as int?,
      caseCode: json['caseCode'] as int?,
      customerId: json['customerId'] as int?,
      workType: json['workType'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      startedAt: json['startedAt'] as String?,
      endedAt: json['endedAt'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      suggestedAmount: json['suggestedAmount'] != null
          ? (json['suggestedAmount'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseCode': caseCode,
      'customerId': customerId,
      'workType': workType,
      'description': description,
      'status': status,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'durationMinutes': durationMinutes,
      'suggestedAmount': suggestedAmount,
    };
  }
}

class Suggestion {
  final int? caseCode;
  final int? customerId;
  final int totalMinutes;
  final double suggestedAmount;

  Suggestion({
    this.caseCode,
    this.customerId,
    required this.totalMinutes,
    required this.suggestedAmount,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      caseCode: json['caseCode'] as int?,
      customerId: json['customerId'] as int?,
      totalMinutes: json['totalMinutes'] as int,
      suggestedAmount: (json['suggestedAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caseCode': caseCode,
      'customerId': customerId,
      'totalMinutes': totalMinutes,
      'suggestedAmount': suggestedAmount,
    };
  }
}