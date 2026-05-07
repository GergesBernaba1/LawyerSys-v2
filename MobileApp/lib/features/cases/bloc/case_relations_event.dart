abstract class CaseRelationsEvent {}

class LoadCaseRelations extends CaseRelationsEvent {
  LoadCaseRelations(this.caseId);
  final int caseId;
}

class CreateCaseRelation extends CaseRelationsEvent {

  CreateCaseRelation({
    required this.caseId,
    required this.relatedCaseId,
    required this.relationType,
    this.notes,
  });
  final int caseId;
  final int relatedCaseId;
  final String relationType;
  final String? notes;
}

class DeleteCaseRelation extends CaseRelationsEvent {
  DeleteCaseRelation(this.id, this.caseId);
  final int id;
  final int caseId;
}
