import '../models/case.dart';

abstract class CasesState {}
class CasesInitial extends CasesState {}
class CasesLoading extends CasesState {}
class CasesLoaded extends CasesState {
  final List<CaseModel> cases;
  CasesLoaded(this.cases);
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
