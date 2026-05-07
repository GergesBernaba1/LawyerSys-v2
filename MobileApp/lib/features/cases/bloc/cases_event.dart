import 'package:qadaya_lawyersys/features/cases/models/case.dart';

abstract class CasesEvent {}
class LoadCases extends CasesEvent {}
class SearchCases extends CasesEvent {
  SearchCases(this.query);
  final String query;
}
class LoadMoreCases extends CasesEvent {}
class RefreshCases extends CasesEvent {}
class SelectCase extends CasesEvent {
  SelectCase(this.caseId);
  final String caseId;
}
class CreateCase extends CasesEvent {
  CreateCase(this.caseModel);
  final CaseModel caseModel;
}
class UpdateCase extends CasesEvent {
  UpdateCase(this.caseModel);
  final CaseModel caseModel;
}
class DeleteCase extends CasesEvent {
  DeleteCase(this.caseId);
  final String caseId;
}
