import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/governments/bloc/governments_event.dart';
import 'package:qadaya_lawyersys/features/governments/bloc/governments_state.dart';
import 'package:qadaya_lawyersys/features/governments/repositories/governments_repository.dart';

class GovernmentsBloc extends Bloc<GovernmentsEvent, GovernmentsState> {
  GovernmentsBloc({required this.governmentsRepository})
      : super(GovernmentsInitial()) {
    on<LoadGovernments>(_onLoad);
    on<LoadGovernmentsNextPage>(_onLoadNextPage);
    on<RefreshGovernments>(_onRefresh);
    on<SearchGovernments>(_onSearch);
    on<CreateGovernment>(_onCreate);
    on<UpdateGovernment>(_onUpdate);
    on<DeleteGovernment>(_onDelete);
  }
  final IGovernmentsRepository governmentsRepository;

  Future<void> _onLoad(
      LoadGovernments event, Emitter<GovernmentsState> emit,) async {
    emit(GovernmentsLoading());
    try {
      final result = await governmentsRepository.getGovernments();
      emit(GovernmentsLoaded(
        governments: result.items,
        totalCount: result.totalCount,
        page: 1,
        hasMore: result.hasMore,
      ),);
    } catch (e) {
      emit(GovernmentsError(e.toString()));
    }
  }

  Future<void> _onLoadNextPage(
      LoadGovernmentsNextPage event, Emitter<GovernmentsState> emit,) async {
    final current = state;
    if (current is! GovernmentsLoaded || !current.hasMore) return;
    emit(GovernmentsLoadingMore(current));
    try {
      final result = await governmentsRepository.getGovernments(
        page: current.page + 1,
        search: current.searchQuery.isEmpty ? null : current.searchQuery,
      );
      emit(GovernmentsLoaded(
        governments: [...current.governments, ...result.items],
        totalCount: result.totalCount,
        page: current.page + 1,
        hasMore: result.hasMore,
        searchQuery: current.searchQuery,
      ),);
    } catch (e) {
      emit(GovernmentsError(e.toString()));
    }
  }

  Future<void> _onRefresh(
      RefreshGovernments event, Emitter<GovernmentsState> emit,) async {
    final searchQuery =
        state is GovernmentsLoaded ? (state as GovernmentsLoaded).searchQuery : '';
    try {
      final result = await governmentsRepository.getGovernments(
        search: searchQuery.isEmpty ? null : searchQuery,
      );
      emit(GovernmentsLoaded(
        governments: result.items,
        totalCount: result.totalCount,
        page: 1,
        hasMore: result.hasMore,
        searchQuery: searchQuery,
      ),);
    } catch (e) {
      emit(GovernmentsError(e.toString()));
    }
  }

  Future<void> _onSearch(
      SearchGovernments event, Emitter<GovernmentsState> emit,) async {
    emit(GovernmentsLoading());
    try {
      final result = await governmentsRepository.getGovernments(
        search: event.query.isEmpty ? null : event.query,
      );
      emit(GovernmentsLoaded(
        governments: result.items,
        totalCount: result.totalCount,
        page: 1,
        hasMore: result.hasMore,
        searchQuery: event.query,
      ),);
    } catch (e) {
      emit(GovernmentsError(e.toString()));
    }
  }

  Future<void> _onCreate(
      CreateGovernment event, Emitter<GovernmentsState> emit,) async {
    emit(GovernmentsLoading());
    try {
      await governmentsRepository.createGovernment(event.data);
      emit(GovernmentOperationSuccess('Government created'));
      final result = await governmentsRepository.getGovernments();
      emit(GovernmentsLoaded(
        governments: result.items,
        totalCount: result.totalCount,
        page: 1,
        hasMore: result.hasMore,
      ),);
    } catch (e) {
      emit(GovernmentsError(e.toString()));
    }
  }

  Future<void> _onUpdate(
      UpdateGovernment event, Emitter<GovernmentsState> emit,) async {
    emit(GovernmentsLoading());
    try {
      await governmentsRepository.updateGovernment(event.id, event.data);
      emit(GovernmentOperationSuccess('Government updated'));
      final result = await governmentsRepository.getGovernments();
      emit(GovernmentsLoaded(
        governments: result.items,
        totalCount: result.totalCount,
        page: 1,
        hasMore: result.hasMore,
      ),);
    } catch (e) {
      emit(GovernmentsError(e.toString()));
    }
  }

  Future<void> _onDelete(
      DeleteGovernment event, Emitter<GovernmentsState> emit,) async {
    emit(GovernmentsLoading());
    try {
      await governmentsRepository.deleteGovernment(event.id);
      emit(GovernmentOperationSuccess('Government deleted'));
      final result = await governmentsRepository.getGovernments();
      emit(GovernmentsLoaded(
        governments: result.items,
        totalCount: result.totalCount,
        page: 1,
        hasMore: result.hasMore,
      ),);
    } catch (e) {
      emit(GovernmentsError(e.toString()));
    }
  }
}
