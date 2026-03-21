class CalendarEvent {
  final String id;
  final String type;
  final String title;
  final String start;
  final String? end;
  final String? notes;
  final int? caseCode;
  final int? entityId;
  final bool isReminderEvent;

  CalendarEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.start,
    this.end,
    this.notes,
    this.caseCode,
    this.entityId,
    required this.isReminderEvent,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      start: json['start'] as String,
      end: json['end'] as String?,
      notes: json['notes'] as String?,
      caseCode: json['caseCode'] as int?,
      entityId: json['entityId'] as int?,
      isReminderEvent: json['isReminderEvent'] as bool ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'start': start,
      'end': end,
      'notes': notes,
      'caseCode': caseCode,
      'entityId': entityId,
      'isReminderEvent': isReminderEvent,
    };
  }
}