import '../models/calendar_event.dart';

abstract class CalendarState {}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<CalendarEvent> events;
  final String view; // 'month' or 'week'
  final DateTime anchorDate;

  CalendarLoaded(
    this.events, {
    this.view = 'month',
    DateTime? anchorDate,
  }) : anchorDate = anchorDate ?? DateTime.now();
}

class CalendarError extends CalendarState {
  final String message;
  CalendarError(this.message);
}