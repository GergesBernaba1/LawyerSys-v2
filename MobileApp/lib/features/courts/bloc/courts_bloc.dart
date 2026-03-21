import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/court.dart';
import '../repositories/courts_repository.dart';
import 'courts_event.dart';
import 'courts_state.dart';

class CourtsBloc extends Bloc<CourtsEvent, CourtsState> {
  final CourtsRepository courtsRepository;

  CourtsBloc({required this.courtsRepository}) : super(CourtsInitial()) {
    on<LoadCourts>(_onLoadCourts);
    on<RefreshCourts>(_onRefreshCourts);
    on<SearchCourts>(_onSearchCourts);
    on<SelectCourt>(_onSelectCourt);
    on<CreateCourt>(_onCreateCourt);
    on<UpdateCourt>(_onUpdateCourt);
    on<DeleteCourt>(_onDeleteCourt);
  }

  Future<void> _onLoadCourts(LoadCourts event, Emitter<CourtsState> emit) async {
    emit(CourtsLoading());
    try {
      final courts = await courtsRepository.getCourts();
      emit(CourtsLoaded(courts));
    } catch (e) {
      emit(CourtsError(e.toString()));
    }
  }

  Future<void> _onRefreshCourts(RefreshCourts event, Emitter<CourtsState> emit) async {
    try {
      final courts = await courtsRepository.getCourts();
      emit(CourtsLoaded(courts));
    } catch (e) {
      emit(CourtsError(e.toString()));
    }
  }

  Future<void> _onSearchCourts(SearchCourts event, Emitter<CourtsState> emit) async {
    emit(CourtsLoading());
    try {
      final courts = await courtsRepository.searchCourts(event.query);
      emit(CourtsLoaded(courts));
    } catch (e) {
      emit(CourtsError(e.toString()));
    }
  }

  Future<void> _onSelectCourt(SelectCourt event, Emitter<CourtsState> emit) async {
    emit(CourtsLoading());
    try {
      final court = await courtsRepository.getCourtById(event.courtId);
      if (court != null) {
        emit(CourtDetailLoaded(court));
      } else {
        emit(CourtsError('Court not found'));
      }
    } catch (e) {
      emit(CourtsError(e.toString()));
    }
  }

  Future<void> _onCreateCourt(CreateCourt event, Emitter<CourtsState> emit) async {
    emit(CourtsLoading());
    try {
      final created = await courtsRepository.createCourt(event.court);
      emit(CourtOperationSuccess('Court created: ${created.name}'));
      final courts = await courtsRepository.getCourts();
      emit(CourtsLoaded(courts));
    } catch (e) {
      emit(CourtsError(e.toString()));
    }
  }

  Future<void> _onUpdateCourt(UpdateCourt event, Emitter<CourtsState> emit) async {
    emit(CourtsLoading());
    try {
      final updated = await courtsRepository.updateCourt(event.court);
      emit(CourtOperationSuccess('Court updated: ${updated.name}'));
      final courts = await courtsRepository.getCourts();
      emit(CourtsLoaded(courts));
    } catch (e) {
      emit(CourtsError(e.toString()));
    }
  }

  Future<void> _onDeleteCourt(DeleteCourt event, Emitter<CourtsState> emit) async {
    emit(CourtsLoading());
    try {
      await courtsRepository.deleteCourt(event.courtId);
      emit(CourtOperationSuccess('Court deleted'));
      final courts = await courtsRepository.getCourts();
      emit(CourtsLoaded(courts));
    } catch (e) {
      emit(CourtsError(e.toString()));
    }
  }
}
