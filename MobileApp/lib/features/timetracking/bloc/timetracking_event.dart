abstract class TimeTrackingEvent {}

class LoadTimeEntries extends TimeTrackingEvent {
  final String? statusFilter;
  LoadTimeEntries({this.statusFilter});
}

class LoadSuggestions extends TimeTrackingEvent {
  final double hourlyRate;
  LoadSuggestions(this.hourlyRate);
}

class LoadCaseOptions extends TimeTrackingEvent {}

class StartTimeEntry extends TimeTrackingEvent {
  final int? caseCode;
  final String workType;
  final String? description;
  final double? hourlyRate;
  final String? statusFilter;

  StartTimeEntry({
    this.caseCode,
    required this.workType,
    this.description,
    this.hourlyRate,
    this.statusFilter,
  });
}

class StopTimeEntry extends TimeTrackingEvent {
  final int entryId;
  final double? hourlyRate;
  final String? statusFilter;

  StopTimeEntry({
    required this.entryId,
    this.hourlyRate,
    this.statusFilter,
  });
}

class FilterByStatus extends TimeTrackingEvent {
  final String statusFilter;
  FilterByStatus(this.statusFilter);
}

class RefreshTimeTracking extends TimeTrackingEvent {
  final double? hourlyRate;
  final String? statusFilter;

  RefreshTimeTracking({
    this.hourlyRate,
    this.statusFilter,
  });
}