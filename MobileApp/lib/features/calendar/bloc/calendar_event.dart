abstract class CalendarEvent {}

class LoadCalendarEvents extends CalendarEvent {
  final String fromDate;
  final String toDate;
  LoadCalendarEvents({required this.fromDate, required this.toDate});
}

class RefreshCalendarEvents extends CalendarEvent {
  final String fromDate;
  final String toDate;
  RefreshCalendarEvents({required this.fromDate, required this.toDate});
}

class ChangeView extends CalendarEvent {
  final String view; // 'month' or 'week'
  ChangeView(this.view);
}

class ChangeDate extends CalendarEvent {
  final DateTime date;
  ChangeDate(this.date);
}