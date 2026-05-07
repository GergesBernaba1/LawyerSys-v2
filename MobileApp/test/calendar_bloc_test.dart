import 'package:flutter_test/flutter_test.dart';
import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_bloc.dart';
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_event.dart' as bloc_event;
import 'package:qadaya_lawyersys/features/calendar/bloc/calendar_state.dart';
import 'package:qadaya_lawyersys/features/calendar/models/calendar_event.dart';
import 'package:qadaya_lawyersys/features/calendar/repositories/calendar_repository.dart';

class FakeCalendarRepository extends CalendarRepository {

  FakeCalendarRepository(this._events) : super(ApiClient());
  final List<CalendarEvent> _events;
  bool createCalled = false;
  String? deletedId;

  @override
  Future<List<CalendarEvent>> getEvents({
    required String fromDate,
    required String toDate,
  }) async {
    return List.of(_events);
  }

  @override
  Future<CalendarEvent> createEvent(Map<String, dynamic> data) async {
    createCalled = true;
    final event = CalendarEvent(
      id: data['id']?.toString() ?? 'new-evt',
      type: data['type']?.toString() ?? 'Hearing',
      title: data['title']?.toString() ?? 'New Event',
      start: data['start']?.toString() ?? '2025-01-01T09:00:00',
      isReminderEvent: data['isReminderEvent'] as bool? ?? false,
    );
    _events.add(event);
    return event;
  }

  @override
  Future<CalendarEvent> updateEvent(String id, Map<String, dynamic> data) async {
    final index = _events.indexWhere((e) => e.id == id);
    final existing = index >= 0 ? _events[index] : _events.first;
    final updated = CalendarEvent(
      id: id,
      type: data['type']?.toString() ?? existing.type,
      title: data['title']?.toString() ?? existing.title,
      start: data['start']?.toString() ?? existing.start,
      isReminderEvent: existing.isReminderEvent,
    );
    if (index >= 0) _events[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteEvent(String id) async {
    deletedId = id;
    _events.removeWhere((e) => e.id == id);
  }
}

void main() {
  final event1 = CalendarEvent(
    id: 'e1',
    type: 'Hearing',
    title: 'Court Hearing',
    start: '2025-06-01T10:00:00',
    isReminderEvent: false,
  );
  final event2 = CalendarEvent(
    id: 'e2',
    type: 'Meeting',
    title: 'Client Meeting',
    start: '2025-06-05T14:00:00',
    isReminderEvent: false,
  );

  late FakeCalendarRepository repo;
  late CalendarBloc bloc;

  const fromDate = '2025-06-01';
  const toDate = '2025-06-30';

  setUp(() {
    repo = FakeCalendarRepository([event1, event2]);
    bloc = CalendarBloc(calendarRepository: repo);
  });

  tearDown(() async {
    await bloc.close();
  });

  group('CalendarBloc', () {
    test('LoadCalendarEvents emits CalendarLoading then CalendarLoaded', () async {
      final states = <CalendarState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(bloc_event.LoadCalendarEvents(fromDate: fromDate, toDate: toDate));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states[0], isA<CalendarLoading>());
      expect(states[1], isA<CalendarLoaded>());

      final loaded = states[1] as CalendarLoaded;
      expect(loaded.events.length, 2);

      await sub.cancel();
    });

    test('CreateCalendarEvent emits CalendarLoading then CalendarOperationSuccess then CalendarLoaded',
        () async {
      final states = <CalendarState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(bloc_event.CreateCalendarEvent(
        {'id': 'e3', 'title': 'Deposition', 'type': 'Deposition', 'start': '2025-06-10T09:00:00'},
        fromDate: fromDate,
        toDate: toDate,
      ),);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, containsAllInOrder([
        isA<CalendarLoading>(),
        isA<CalendarOperationSuccess>(),
        isA<CalendarLoaded>(),
      ]),);

      expect(repo.createCalled, isTrue);
      expect(await repo.getEvents(fromDate: fromDate, toDate: toDate), hasLength(3));

      await sub.cancel();
    });

    test('DeleteCalendarEvent emits CalendarLoading then CalendarOperationSuccess then CalendarLoaded',
        () async {
      final states = <CalendarState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(bloc_event.DeleteCalendarEvent('e1', fromDate: fromDate, toDate: toDate));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, containsAllInOrder([
        isA<CalendarLoading>(),
        isA<CalendarOperationSuccess>(),
        isA<CalendarLoaded>(),
      ]),);

      expect(repo.deletedId, 'e1');
      expect(await repo.getEvents(fromDate: fromDate, toDate: toDate), hasLength(1));

      final loaded = states.last as CalendarLoaded;
      expect(loaded.events.any((e) => e.id == 'e1'), isFalse);

      await sub.cancel();
    });
  });
}
