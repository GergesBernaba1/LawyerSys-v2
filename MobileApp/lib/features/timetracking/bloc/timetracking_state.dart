import '../models/time_entry.dart';

abstract class TimeTrackingState {}

class TimeTrackingInitial extends TimeTrackingState {}

class TimeTrackingLoading extends TimeTrackingState {}

class TimeTrackingLoaded extends TimeTrackingState {
  final List<TimeEntry> entries;
  final List<Suggestion> suggestions;
  final List<Map<String, dynamic>> caseOptions;
  final String statusFilter;
  final double hourlyRate;

  TimeTrackingLoaded({
    required this.entries,
    required this.suggestions,
    required this.caseOptions,
    required this.statusFilter,
    required this.hourlyRate,
  });
}

class TimeTrackingError extends TimeTrackingState {
  final String message;
  TimeTrackingError(this.message);
}