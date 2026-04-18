import '../models/case.dart';

abstract class CasesEvent {}
class LoadCases extends CasesEvent {}
class SearchCases extends CasesEvent {
  final String query;
  SearchCases(this.query);
}
class LoadMoreCases extends CasesEvent {}
class RefreshCases extends CasesEvent {}
class SelectCase extends CasesEvent {
  final String caseId;
  SelectCase(this.caseId);
}
class CreateCase extends CasesEvent {
  final CaseModel caseModel;
  CreateCase(this.caseModel);
}
class UpdateCase extends CasesEvent {
  final CaseModel caseModel;
  UpdateCase(this.caseModel);
}
class DeleteCase extends CasesEvent {
  final String caseId;
  DeleteCase(this.caseId);
}
