import 'package:qadaya_lawyersys/features/cases/models/case.dart';

abstract class CasesState {}
class CasesInitial extends CasesState {}
class CasesLoading extends CasesState {}
class CasesLoaded extends CasesState {
  
  CasesLoaded(
    this.cases, {
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });
  final List<CaseModel> cases;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  CasesLoaded copyWith({
    List<CaseModel>? cases,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CasesLoaded(
      cases ?? this.cases,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
class CasesError extends CasesState {
  CasesError(this.message);
  final String message;
}
class CasesOffline extends CasesState {}
class CaseDetailLoaded extends CasesState {
  CaseDetailLoaded(this.detail);
  final CaseModel detail;
}

class CaseOperationSuccess extends CasesState {
  CaseOperationSuccess(this.message);
  final String message;
}

class CaseStatusHistoryLoaded extends CasesState {
  CaseStatusHistoryLoaded(this.history);
  final List<Map<String, dynamic>> history;
}

class CaseCourtHistoryLoaded extends CasesState {
  CaseCourtHistoryLoaded(this.history);
  final List<Map<String, dynamic>> history;
}
