import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/sitings_repository.dart';
import 'sitings_event.dart';
import 'sitings_state.dart';

class SitingsBloc extends Bloc<SitingsEvent, SitingsState> {
  final SitingsRepository repository;
  String? _lastSearch;

  SitingsBloc({required this.repository}) : super(SitingsInitial()) {
    on<LoadSitings>(_onLoadSitings);
    on<RefreshSitings>(_onRefreshSitings);
    on<CreateSiting>(_onCreateSiting);
    on<UpdateSiting>(_onUpdateSiting);
    on<DeleteSiting>(_onDeleteSiting);
  }

  Future<void> _onLoadSitings(LoadSitings event, Emitter<SitingsState> emit) async {
    emit(SitingsLoading());
    try {
      _lastSearch = event.search;
      final sitings = await repository.getSitings(search: event.search);
      emit(SitingsLoaded(sitings));
    } catch (e) {
      emit(SitingsError(e.toString()));
    }
  }

  Future<void> _onRefreshSitings(RefreshSitings event, Emitter<SitingsState> emit) async {
    try {
      final sitings = await repository.getSitings(search: _lastSearch);
      emit(SitingsLoaded(sitings));
    } catch (e) {
      emit(SitingsError(e.toString()));
    }
  }

  Future<void> _onCreateSiting(CreateSiting event, Emitter<SitingsState> emit) async {
    emit(SitingsLoading());
    try {
      await repository.createSiting(event.data);
      emit(SitingOperationSuccess('Court sitting created successfully')); // TODO localize
      final sitings = await repository.getSitings(search: _lastSearch);
      emit(SitingsLoaded(sitings));
    } catch (e) {
      emit(SitingsError(e.toString()));
    }
  }

  Future<void> _onUpdateSiting(UpdateSiting event, Emitter<SitingsState> emit) async {
    emit(SitingsLoading());
    try {
      await repository.updateSiting(event.id, event.data);
      emit(SitingOperationSuccess('Court sitting updated successfully')); // TODO localize
      final sitings = await repository.getSitings(search: _lastSearch);
      emit(SitingsLoaded(sitings));
    } catch (e) {
      emit(SitingsError(e.toString()));
    }
  }

  Future<void> _onDeleteSiting(DeleteSiting event, Emitter<SitingsState> emit) async {
    emit(SitingsLoading());
    try {
      await repository.deleteSiting(event.id);
      emit(SitingOperationSuccess('Court sitting deleted successfully')); // TODO localize
      final sitings = await repository.getSitings(search: _lastSearch);
      emit(SitingsLoaded(sitings));
    } catch (e) {
      emit(SitingsError(e.toString()));
    }
  }
}
