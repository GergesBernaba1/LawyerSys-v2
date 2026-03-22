import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/calendar_repository.dart';
import 'calendar_event.dart' as bloc_calendar_event;
import 'calendar_state.dart';

class CalendarBloc extends Bloc<bloc_calendar_event.CalendarEvent, CalendarState> {
  final CalendarRepository calendarRepository;

  CalendarBloc({required this.calendarRepository}) : super(CalendarInitial()) {
    on<bloc_calendar_event.LoadCalendarEvents>(_onLoadCalendarEvents);
    on<bloc_calendar_event.RefreshCalendarEvents>(_onRefreshCalendarEvents);
    on<bloc_calendar_event.ChangeView>(_onChangeView);
    on<bloc_calendar_event.ChangeDate>(_onChangeDate);
  }

  Future<void> _onLoadCalendarEvents(
      bloc_calendar_event.LoadCalendarEvents event, Emitter<CalendarState> emit) async {
    emit(CalendarLoading());
    try {
      final events = await calendarRepository.getEvents(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );
      emit(CalendarLoaded(events));
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }

  Future<void> _onRefreshCalendarEvents(
      bloc_calendar_event.RefreshCalendarEvents event, Emitter<CalendarState> emit) async {
    try {
      final events = await calendarRepository.getEvents(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );
      emit(CalendarLoaded(events));
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }

  void _onChangeView(bloc_calendar_event.ChangeView event, Emitter<CalendarState> emit) {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      emit(CalendarLoaded(
        currentState.events,
        view: event.view,
        anchorDate: currentState.anchorDate,
      ));
    } else if (state is CalendarInitial) {
      emit(CalendarLoaded(
        [],
        view: event.view,
        anchorDate: DateTime.now(),
      ));
    }
  }

  void _onChangeDate(bloc_calendar_event.ChangeDate event, Emitter<CalendarState> emit) {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      emit(CalendarLoaded(
        currentState.events,
        view: currentState.view,
        anchorDate: event.date,
      ));
    } else if (state is CalendarInitial) {
      emit(CalendarLoaded(
        [],
        view: 'month',
        anchorDate: event.date,
      ));
    }
  }
}