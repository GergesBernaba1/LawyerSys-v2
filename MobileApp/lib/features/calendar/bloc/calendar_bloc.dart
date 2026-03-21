import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/calendar_event.dart';
import '../repositories/calendar_repository.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CalendarRepository calendarRepository;

  CalendarBloc({required this.calendarRepository}) : super(CalendarInitial()) {
    on<LoadCalendarEvents>(_onLoadCalendarEvents);
    on<RefreshCalendarEvents>(_onRefreshCalendarEvents);
    on<ChangeView>(_onChangeView);
    on<ChangeDate>(_onChangeDate);
  }

  Future<void> _onLoadCalendarEvents(
      LoadCalendarEvents event, Emitter<CalendarState> emit) async {
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
      RefreshCalendarEvents event, Emitter<CalendarState> emit) async {
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

  void _onChangeView(ChangeView event, Emitter<CalendarState> emit) {
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

  void _onChangeDate(ChangeDate event, Emitter<CalendarState> emit) {
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