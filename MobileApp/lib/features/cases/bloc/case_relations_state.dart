import 'package:qadaya_lawyersys/features/cases/models/case_relation.dart';

abstract class CaseRelationsState {}

class CaseRelationsInitial extends CaseRelationsState {}

class CaseRelationsLoading extends CaseRelationsState {}

class CaseRelationsLoaded extends CaseRelationsState {
  CaseRelationsLoaded(this.relations);
  final List<CaseRelation> relations;
}

class CaseRelationsError extends CaseRelationsState {
  CaseRelationsError(this.message);
  final String message;
}

class CaseRelationSuccess extends CaseRelationsState {
  CaseRelationSuccess(this.message);
  final String message;
}
