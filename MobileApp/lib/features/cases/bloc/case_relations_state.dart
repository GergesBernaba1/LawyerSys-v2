import '../models/case_relation.dart';

abstract class CaseRelationsState {}

class CaseRelationsInitial extends CaseRelationsState {}

class CaseRelationsLoading extends CaseRelationsState {}

class CaseRelationsLoaded extends CaseRelationsState {
  final List<CaseRelation> relations;
  CaseRelationsLoaded(this.relations);
}

class CaseRelationsError extends CaseRelationsState {
  final String message;
  CaseRelationsError(this.message);
}

class CaseRelationSuccess extends CaseRelationsState {
  final String message;
  CaseRelationSuccess(this.message);
}
