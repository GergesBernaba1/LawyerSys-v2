abstract class CaseRelationsEvent {}

class LoadCaseRelations extends CaseRelationsEvent {
  final int caseCode;
  LoadCaseRelations(this.caseCode);
}

class RefreshCaseRelations extends CaseRelationsEvent {
  final int caseCode;
  RefreshCaseRelations(this.caseCode);
}
