import 'package:qadaya_lawyersys/features/timetracking/models/time_entry.dart';

abstract class TimeTrackingState {}

class TimeTrackingInitial extends TimeTrackingState {}

class TimeTrackingLoading extends TimeTrackingState {}

class TimeTrackingLoaded extends TimeTrackingState {

  TimeTrackingLoaded({
    required this.entries,
    required this.suggestions,
    required this.caseOptions,
    required this.statusFilter,
    required this.hourlyRate,
  });
  final List<TimeEntry> entries;
  final List<Suggestion> suggestions;
  final List<Map<String, dynamic>> caseOptions;
  final String statusFilter;
  final double hourlyRate;
}

class TimeTrackingError extends TimeTrackingState {
  TimeTrackingError(this.message);
  final String message;
}
