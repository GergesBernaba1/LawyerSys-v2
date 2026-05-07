abstract class CalendarEvent {}

class LoadCalendarEvents extends CalendarEvent {
  LoadCalendarEvents({required this.fromDate, required this.toDate});
  final String fromDate;
  final String toDate;
}

class RefreshCalendarEvents extends CalendarEvent {
  RefreshCalendarEvents({required this.fromDate, required this.toDate});
  final String fromDate;
  final String toDate;
}

class ChangeView extends CalendarEvent { // 'month' or 'week'
  ChangeView(this.view);
  final String view;
}

class ChangeDate extends CalendarEvent {
  ChangeDate(this.date);
  final DateTime date;
}

class CreateCalendarEvent extends CalendarEvent {
  CreateCalendarEvent(this.data, {required this.fromDate, required this.toDate});
  final Map<String, dynamic> data;
  final String fromDate;
  final String toDate;
}

class UpdateCalendarEvent extends CalendarEvent {
  UpdateCalendarEvent(this.id, this.data, {required this.fromDate, required this.toDate});
  final String id;
  final Map<String, dynamic> data;
  final String fromDate;
  final String toDate;
}

class DeleteCalendarEvent extends CalendarEvent {
  DeleteCalendarEvent(this.id, {required this.fromDate, required this.toDate});
  final String id;
  final String fromDate;
  final String toDate;
}
