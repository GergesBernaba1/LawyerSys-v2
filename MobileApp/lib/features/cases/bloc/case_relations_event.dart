abstract class CaseRelationsEvent {}

class LoadCaseRelations extends CaseRelationsEvent {
  final int caseId;
  LoadCaseRelations(this.caseId);
}

class CreateCaseRelation extends CaseRelationsEvent {
  final int caseId;
  final int relatedCaseId;
  final String relationType;
  final String? notes;

  CreateCaseRelation({
    required this.caseId,
    required this.relatedCaseId,
    required this.relationType,
    this.notes,
  });
}

class DeleteCaseRelation extends CaseRelationsEvent {
  final int id;
  final int caseId;
  DeleteCaseRelation(this.id, this.caseId);
}
