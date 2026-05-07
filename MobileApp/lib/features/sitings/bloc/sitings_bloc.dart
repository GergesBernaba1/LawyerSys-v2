import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/sitings/bloc/sitings_event.dart';
import 'package:qadaya_lawyersys/features/sitings/bloc/sitings_state.dart';
import 'package:qadaya_lawyersys/features/sitings/repositories/sitings_repository.dart';

class SitingsBloc extends Bloc<SitingsEvent, SitingsState> {

  SitingsBloc({required this.repository}) : super(SitingsInitial()) {
    on<LoadSitings>(_onLoadSitings);
    on<RefreshSitings>(_onRefreshSitings);
    on<CreateSiting>(_onCreateSiting);
    on<UpdateSiting>(_onUpdateSiting);
    on<DeleteSiting>(_onDeleteSiting);
  }
  final SitingsRepository repository;
  String? _lastSearch;

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
