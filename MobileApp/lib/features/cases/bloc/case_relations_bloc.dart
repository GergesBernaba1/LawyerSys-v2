import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/case_relations_repository.dart';
import 'case_relations_event.dart';
import 'case_relations_state.dart';

class CaseRelationsBloc extends Bloc<CaseRelationsEvent, CaseRelationsState> {
  final CaseRelationsRepository repository;

  CaseRelationsBloc({required this.repository}) : super(CaseRelationsInitial()) {
    on<LoadCaseRelations>(_onLoad);
    on<CreateCaseRelation>(_onCreate);
    on<DeleteCaseRelation>(_onDelete);
  }

  Future<void> _onLoad(
      LoadCaseRelations e, Emitter<CaseRelationsState> emit) async {
    emit(CaseRelationsLoading());
    try {
      emit(CaseRelationsLoaded(await repository.getRelations(e.caseId)));
    } catch (err) {
      emit(CaseRelationsError(err.toString()));
    }
  }

  Future<void> _onCreate(
      CreateCaseRelation e, Emitter<CaseRelationsState> emit) async {
    try {
      await repository.createRelation(
        e.caseId,
        e.relatedCaseId,
        e.relationType,
        notes: e.notes,
      );
      emit(CaseRelationSuccess('Relation added'));
      emit(CaseRelationsLoaded(await repository.getRelations(e.caseId)));
    } catch (err) {
      emit(CaseRelationsError(err.toString()));
    }
  }

  Future<void> _onDelete(
      DeleteCaseRelation e, Emitter<CaseRelationsState> emit) async {
    try {
      await repository.deleteRelation(e.id);
      emit(CaseRelationSuccess('Relation removed'));
      emit(CaseRelationsLoaded(await repository.getRelations(e.caseId)));
    } catch (err) {
      emit(CaseRelationsError(err.toString()));
    }
  }
}
