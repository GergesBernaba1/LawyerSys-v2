import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/hearing.dart';
import '../repositories/hearings_repository.dart';
import 'hearings_event.dart';
import 'hearings_state.dart';

class HearingsBloc extends Bloc<HearingsEvent, HearingsState> {
  final HearingsRepository hearingsRepository;

  HearingsBloc({required this.hearingsRepository}) : super(HearingsInitial()) {
    on<LoadHearings>(_onLoadHearings);
    on<SearchHearings>(_onSearchHearings);
    on<RefreshHearings>(_onRefreshHearings);
    on<LoadHearingDetail>(_onLoadHearingDetail);
    on<CreateHearing>(_onCreateHearing);
    on<UpdateHearing>(_onUpdateHearing);
    on<DeleteHearing>(_onDeleteHearing);
  }

  Future<void> _onLoadHearings(LoadHearings event, Emitter<HearingsState> emit) async {
    emit(HearingsLoading());
    try {
      final hearings = await hearingsRepository.getHearings();
      emit(HearingsLoaded(hearings));
    } catch (e) {
      emit(HearingsError(e.toString()));
    }
  }

  Future<void> _onCreateHearing(CreateHearing event, Emitter<HearingsState> emit) async {
    emit(HearingsLoading());
    try {
      final hearing = event.hearing as Hearing;
      await hearingsRepository.createHearing(hearing);
      final hearings = await hearingsRepository.getHearings();
      emit(HearingsLoaded(hearings));
      emit(HearingOperationSuccess('Hearing created successfully'));
    } catch (e) {
      emit(HearingsError(e.toString()));
    }
  }

  Future<void> _onUpdateHearing(UpdateHearing event, Emitter<HearingsState> emit) async {
    emit(HearingsLoading());
    try {
      final hearing = event.hearing as Hearing;
      await hearingsRepository.updateHearing(hearing);
      final hearings = await hearingsRepository.getHearings();
      emit(HearingsLoaded(hearings));
      emit(HearingOperationSuccess('Hearing updated successfully'));
    } catch (e) {
      emit(HearingsError(e.toString()));
    }
  }

  Future<void> _onDeleteHearing(DeleteHearing event, Emitter<HearingsState> emit) async {
    emit(HearingsLoading());
    try {
      await hearingsRepository.deleteHearing(event.hearingId);
      final hearings = await hearingsRepository.getHearings();
      emit(HearingsLoaded(hearings));
      emit(HearingOperationSuccess('Hearing deleted successfully'));
    } catch (e) {
      emit(HearingsError(e.toString()));
    }
  }

  Future<void> _onSearchHearings(SearchHearings event, Emitter<HearingsState> emit) async {
    emit(HearingsLoading());
    try {
      final hearings = await hearingsRepository.searchHearings(event.query);
      emit(HearingsLoaded(hearings));
    } catch (e) {
      emit(HearingsError(e.toString()));
    }
  }

  Future<void> _onRefreshHearings(RefreshHearings event, Emitter<HearingsState> emit) async {
    try {
      final hearings = await hearingsRepository.getHearings();
      emit(HearingsLoaded(hearings));
    } catch (e) {
      emit(HearingsError(e.toString()));
    }
  }

  Future<void> _onLoadHearingDetail(LoadHearingDetail event, Emitter<HearingsState> emit) async {
    emit(HearingsLoading());
    try {
      final hearing = await hearingsRepository.getHearingById(event.hearingId);
      if (hearing != null) {
        emit(HearingDetailLoaded(hearing));
      } else {
        emit(HearingsError('Hearing not found'));
      }
    } catch (e) {
      emit(HearingsError(e.toString()));
    }
  }
}
