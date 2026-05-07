import 'package:qadaya_lawyersys/features/calendar/models/calendar_event.dart';

abstract class CalendarState {}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {

  CalendarLoaded(
    this.events, {
    this.view = 'month',
    DateTime? anchorDate,
  }) : anchorDate = anchorDate ?? DateTime.now();
  final List<CalendarEvent> events;
  final String view; // 'month' or 'week'
  final DateTime anchorDate;
}

class CalendarError extends CalendarState {
  CalendarError(this.message);
  final String message;
}

class CalendarOperationSuccess extends CalendarState {
  CalendarOperationSuccess(this.message, this.events,
      {this.view = 'month', DateTime? anchorDate,})
      : anchorDate = anchorDate ?? DateTime.now();
  final String message;
  final List<CalendarEvent> events;
  final String view;
  final DateTime anchorDate;
}
