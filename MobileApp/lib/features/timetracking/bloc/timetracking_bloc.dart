import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/time_entry.dart';
import '../repositories/timetracking_repository.dart';
import 'timetracking_event.dart';
import 'timetracking_state.dart';

class TimeTrackingBloc extends Bloc<TimeTrackingEvent, TimeTrackingState> {
  final TimeTrackingRepository timeTrackingRepository;

  TimeTrackingBloc({required this.timeTrackingRepository})
      : super(TimeTrackingInitial()) {
    on<LoadTimeEntries>(_onLoadTimeEntries);
    on<LoadSuggestions>(_onLoadSuggestions);
    on<LoadCaseOptions>(_onLoadCaseOptions);
    on<StartTimeEntry>(_onStartTimeEntry);
    on<StopTimeEntry>(_onStopTimeEntry);
    on<FilterByStatus>(_onFilterByStatus);
    on<RefreshTimeTracking>(_onRefreshTimeTracking);
  }

   Future<void> _onLoadTimeEntries(
       LoadTimeEntries event, Emitter<TimeTrackingState> emit) async {
     if (state is! TimeTrackingLoading) {
       emit(TimeTrackingLoading());
     }
     try {
       final entries = await timeTrackingRepository.getTimeEntries(
         status: event.statusFilter,
       );
       emit(TimeTrackingLoaded(
         entries: entries,
         suggestions: state is TimeTrackingLoaded
             ? (state as TimeTrackingLoaded).suggestions
             : [],
         caseOptions: state is TimeTrackingLoaded
             ? (state as TimeTrackingLoaded).caseOptions
             : [],
         statusFilter: event.statusFilter,
         hourlyRate: state is TimeTrackingLoaded
             ? (state as TimeTrackingLoaded).hourlyRate
             : 0,
       ));
     } catch (e) {
       emit(TimeTrackingError(e.toString()));
     }
   }

   Future<void> _onLoadSuggestions(
       LoadSuggestions event, Emitter<TimeTrackingState> emit) async {
     try {
       final suggestions = await timeTrackingRepository.getSuggestions(
         hourlyRate: event.hourlyRate,
       );
       if (state is TimeTrackingLoaded) {
         final currentState = state as TimeTrackingLoaded;
         emit(TimeTrackingLoaded(
           entries: currentState.entries,
           suggestions: suggestions,
           caseOptions: currentState.caseOptions,
           statusFilter: currentState.statusFilter,
           hourlyRate: event.hourlyRate,
         ));
       }
     } catch (e) {
       emit(TimeTrackingError(e.toString()));
     }
   }

  Future<void> _onLoadCaseOptions(
      LoadCaseOptions event, Emitter<TimeTrackingState> emit) async {
    try {
      final caseOptions = await timeTrackingRepository.getCaseOptions();
      if (state is TimeTrackingLoaded) {
        final currentState = state as TimeTrackingLoaded;
        emit(TimeTrackingLoaded(
          entries: currentState.entries,
          suggestions: currentState.suggestions,
          caseOptions: caseOptions,
          statusFilter: currentState.statusFilter,
        ));
      }
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  Future<void> _onStartTimeEntry(
      StartTimeEntry event, Emitter<TimeTrackingState> emit) async {
    try {
      await timeTrackingRepository.startTimeEntry(
        caseCode: event.caseCode,
        workType: event.workType,
        description: event.description,
      );
      // Reload data after starting
      add(LoadTimeEntries(statusFilter: event.statusFilter ?? 'All'));
      add(LoadSuggestions(event.hourlyRate ?? 0));
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  Future<void> _onStopTimeEntry(
      StopTimeEntry event, Emitter<TimeTrackingState> emit) async {
    try {
      await timeTrackingRepository.stopTimeEntry(
        entryId: event.entryId,
        hourlyRate: event.hourlyRate,
      );
      // Reload data after stopping
      add(LoadTimeEntries(statusFilter: event.statusFilter ?? 'All'));
      add(LoadSuggestions(event.hourlyRate ?? 0));
    } catch (e) {
      emit(TimeTrackingError(e.toString()));
    }
  }

  void _onFilterByStatus(
      FilterByStatus event, Emitter<TimeTrackingState> emit) {
    add(LoadTimeEntries(statusFilter: event.statusFilter));
  }

  Future<void> _onRefreshTimeTracking(
      RefreshTimeTracking event, Emitter<TimeTrackingState> emit) async {
    add(LoadTimeEntries(statusFilter: event.statusFilter ?? 'All'));
    add(LoadSuggestions(event.hourlyRate ?? 0));
    add(LoadCaseOptions());
  }
}