import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_event.dart';
import 'package:qadaya_lawyersys/features/cases/bloc/cases_state.dart';
import 'package:qadaya_lawyersys/features/cases/models/case.dart';
import 'package:qadaya_lawyersys/features/cases/repositories/cases_repository.dart';

class CasesBloc extends Bloc<CasesEvent, CasesState> {

  CasesBloc({required this.casesRepository}) : super(CasesInitial()) {
    on<LoadCases>(_onLoadCases);
    on<LoadMoreCases>(_onLoadMoreCases);
    on<SearchCases>(_onSearchCases);
    on<RefreshCases>(_onRefreshCases);
    on<SelectCase>(_onSelectCase);
    on<CreateCase>(_onCreateCase);
    on<UpdateCase>(_onUpdateCase);
    on<DeleteCase>(_onDeleteCase);
    on<ChangeCaseStatus>(_onChangeCaseStatus);
    on<LoadCaseStatusHistory>(_onLoadCaseStatusHistory);
  }
  final CasesRepository casesRepository;
  final List<CaseModel> _cases = [];
  static const int _pageSize = 20;

  Future<void> _onLoadCases(LoadCases event, Emitter<CasesState> emit) async {
    emit(CasesLoading());
    try {
      final cases = await casesRepository.getCases();
      _cases
        ..clear()
        ..addAll(cases);
      emit(CasesLoaded(
        cases,
        hasMore: cases.length >= _pageSize,
      ),);
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onLoadMoreCases(
      LoadMoreCases event, Emitter<CasesState> emit,) async {
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
      );
      
      _cases.addAll(newCases);
      
      emit(CasesLoaded(
        List.from(_cases),
        currentPage: nextPage,
        hasMore: newCases.length >= _pageSize,
      ),);
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
        hasMore: false, // Search doesn't paginate
      ),);
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onRefreshCases(RefreshCases event, Emitter<CasesState> emit) async {
    try {
      final cases = await casesRepository.getCases();
      _cases
        ..clear()
        ..addAll(cases);
      emit(CasesLoaded(
        cases,
        hasMore: cases.length >= _pageSize,
      ),);
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
      final cases = await casesRepository.getCases();
      _cases
        ..clear()
        ..addAll(cases);
      emit(CasesLoaded(
        _cases,
        hasMore: cases.length >= _pageSize,
      ),);
      emit(CaseOperationSuccess('Case created successfully'));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onUpdateCase(UpdateCase event, Emitter<CasesState> emit) async {
    try {
      await casesRepository.updateCase(event.caseModel);
      final cases = await casesRepository.getCases();
      _cases
        ..clear()
        ..addAll(cases);
      emit(CasesLoaded(
        _cases,
        hasMore: cases.length >= _pageSize,
      ),);
      emit(CaseOperationSuccess('Case updated successfully'));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onDeleteCase(DeleteCase event, Emitter<CasesState> emit) async {
    try {
      await casesRepository.deleteCase(event.caseId);
      final cases = await casesRepository.getCases();
      _cases
        ..clear()
        ..addAll(cases);
      emit(CasesLoaded(
        _cases,
        hasMore: cases.length >= _pageSize,
      ),);
      emit(CaseOperationSuccess('Case deleted successfully'));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onChangeCaseStatus(
      ChangeCaseStatus event, Emitter<CasesState> emit,) async {
    try {
      await casesRepository.changeStatus(event.caseCode, event.status);
      emit(CaseOperationSuccess('Status updated successfully'));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }

  Future<void> _onLoadCaseStatusHistory(
      LoadCaseStatusHistory event, Emitter<CasesState> emit,) async {
    emit(CasesLoading());
    try {
      final history = await casesRepository.getStatusHistory(event.caseCode);
      emit(CaseStatusHistoryLoaded(history));
    } catch (e) {
      emit(CasesError(e.toString()));
    }
  }
}
