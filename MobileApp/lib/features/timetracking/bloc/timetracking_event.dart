abstract class TimeTrackingEvent {}

class LoadTimeEntries extends TimeTrackingEvent {
  LoadTimeEntries({this.statusFilter});
  final String? statusFilter;
}

class LoadSuggestions extends TimeTrackingEvent {
  LoadSuggestions(this.hourlyRate);
  final double hourlyRate;
}

class LoadCaseOptions extends TimeTrackingEvent {}

class StartTimeEntry extends TimeTrackingEvent {

  StartTimeEntry({
    this.caseCode,
    required this.workType,
    this.description,
    this.hourlyRate,
    this.statusFilter,
  });
  final int? caseCode;
  final String workType;
  final String? description;
  final double? hourlyRate;
  final String? statusFilter;
}

class StopTimeEntry extends TimeTrackingEvent {

  StopTimeEntry({
    required this.entryId,
    this.hourlyRate,
    this.statusFilter,
  });
  final int entryId;
  final double? hourlyRate;
  final String? statusFilter;
}

class FilterByStatus extends TimeTrackingEvent {
  FilterByStatus(this.statusFilter);
  final String statusFilter;
}

class RefreshTimeTracking extends TimeTrackingEvent {

  RefreshTimeTracking({
    this.hourlyRate,
    this.statusFilter,
  });
  final double? hourlyRate;
  final String? statusFilter;
}
