import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/case.dart';
import '../repositories/cases_repository.dart';
import 'cases_event.dart';
import 'cases_state.dart';

class CasesBloc extends Bloc<CasesEvent, CasesState> {
  final CasesRepository casesRepository;
  final List<CaseModel> _cases = [];
  static const int _pageSize = 20;

  CasesBloc({required this.casesRepository}) : super(CasesInitial()) {
    on<LoadCases>(_onLoadCases);
    on<LoadMoreCases>(_onLoadMoreCases);
    on<SearchCases>(_onSearchCases);
    on<RefreshCases>(_onRefreshCases);
    on<SelectCase>(_onSelectCase);
    on<CreateCase>(_onCreateCase);
    on<UpdateCase>(_onUpdateCase);
    on<DeleteCase>(_onDeleteCase);
  }

  Future<void> _onLoadCases(LoadCases event, Emitter<CasesState> emit) async {
    emit(CasesLoading());
    try {
      final cases = await casesRepository.getCases(page: 1, pageSize: _pageSize);
      _cases.clear();
      _cases.addAll(cases);
      emit(CasesLoaded(
        cases,
        currentPage: 1,
        hasMore: cases.length >= _pageSize,
      ));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onLoadMoreCases(
      LoadMoreCases event, Emitter<CasesState> emit) async {
    final currentState = state;
    if (currentState is! CasesLoaded || 
        currentState.isLoadingMore || 
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    
    try {
      final nextPage = currentState.currentPage + 1;
      final newCases = await casesRepository.getCases(
        page: nextPage, 
        pageSize: _pageSize,
      );
      
      _cases.addAll(newCases);
      
      emit(CasesLoaded(
        List.from(_cases),
        currentPage: nextPage,
        hasMore: newCases.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onSearchCases(SearchCases event, Emitter<CasesState> emit) async {
    emit(CasesLoading());
    try {
      final results = await casesRepository.searchCases(event.query);
      emit(CasesLoaded(
        results,
        currentPage: 1,
        hasMore: false, // Search doesn't paginate
      ));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onRefreshCases(RefreshCases event, Emitter<CasesState> emit) async {
    try {
      final cases = await casesRepository.getCases(page: 1, pageSize: _pageSize);
      _cases.clear();
      _cases.addAll(cases);
      emit(CasesLoaded(
        cases,
        currentPage: 1,
        hasMore: cases.length >= _pageSize,
      ));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onSelectCase(SelectCase event, Emitter<CasesState> emit) async {
    try {
      final detail = await casesRepository.getCaseById(event.caseId);
      if (detail != null) {
        emit(CaseDetailLoaded(detail));
      } else {
        emit(CasesError('Case not found'));
      }
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onCreateCase(CreateCase event, Emitter<CasesState> emit) async {
    try {
      await casesRepository.createCase(event.caseModel);
      final cases = await casesRepository.getCases(page: 1, pageSize: _pageSize);
      _cases.clear();
      _cases.addAll(cases);
      emit(CasesLoaded(
        _cases,
        currentPage: 1,
        hasMore: cases.length >= _pageSize,
      ));
      emit(CaseOperationSuccess('Case created successfully'));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onUpdateCase(UpdateCase event, Emitter<CasesState> emit) async {
    try {
      await casesRepository.updateCase(event.caseModel);
      final cases = await casesRepository.getCases(page: 1, pageSize: _pageSize);
      _cases.clear();
      _cases.addAll(cases);
      emit(CasesLoaded(
        _cases,
        currentPage: 1,
        hasMore: cases.length >= _pageSize,
      ));
      emit(CaseOperationSuccess('Case updated successfully'));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onDeleteCase(DeleteCase event, Emitter<CasesState> emit) async {
    try {
      await casesRepository.deleteCase(event.caseId);
      final cases = await casesRepository.getCases(page: 1, pageSize: _pageSize);
      _cases.clear();
      _cases.addAll(cases);
      emit(CasesLoaded(
        _cases,
        currentPage: 1,
        hasMore: cases.length >= _pageSize,
      ));
      emit(CaseOperationSuccess('Case deleted successfully'));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }
}


