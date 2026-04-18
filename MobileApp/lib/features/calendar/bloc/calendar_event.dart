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

class CreateCalendarEvent extends CalendarEvent {
  final Map<String, dynamic> data;
  final String fromDate;
  final String toDate;
  CreateCalendarEvent(this.data, {required this.fromDate, required this.toDate});
}

class UpdateCalendarEvent extends CalendarEvent {
  final String id;
  final Map<String, dynamic> data;
  final String fromDate;
  final String toDate;
  UpdateCalendarEvent(this.id, this.data, {required this.fromDate, required this.toDate});
}

class DeleteCalendarEvent extends CalendarEvent {
  final String id;
  final String fromDate;
  final String toDate;
  DeleteCalendarEvent(this.id, {required this.fromDate, required this.toDate});
}