import '../models/case.dart';

abstract class CasesState {}
class CasesInitial extends CasesState {}
class CasesLoading extends CasesState {}
class CasesLoaded extends CasesState {
  final List<CaseModel> cases;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  
  CasesLoaded(
    this.cases, {
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

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
  final String message;
  CasesError(this.message);
}
class CasesOffline extends CasesState {}
class CaseDetailLoaded extends CasesState {
  final CaseModel detail;
  CaseDetailLoaded(this.detail);
}

class CaseOperationSuccess extends CasesState {
  final String message;
  CaseOperationSuccess(this.message);
}
