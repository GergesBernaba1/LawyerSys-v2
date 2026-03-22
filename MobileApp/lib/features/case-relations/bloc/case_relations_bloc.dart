import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/case_relations_repository.dart';
import 'case_relations_event.dart';
import 'case_relations_state.dart';

class CaseRelationsBloc extends Bloc<CaseRelationsEvent, CaseRelationsState> {
  final CaseRelationsRepository caseRelationsRepository;

  CaseRelationsBloc({required this.caseRelationsRepository}) : super(CaseRelationsInitial()) {
    on<LoadCaseRelations>(_onLoad);
    on<RefreshCaseRelations>(_onRefresh);
  }

  Future<void> _onLoad(LoadCaseRelations event, Emitter<CaseRelationsState> emit) async {
    emit(CaseRelationsLoading());
    try {
      final relations = await caseRelationsRepository.getCaseRelations(event.caseCode);
      emit(CaseRelationsLoaded(relations));
    } catch (e) {
      emit(CaseRelationsError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshCaseRelations event, Emitter<CaseRelationsState> emit) async {
    try {
      final relations = await caseRelationsRepository.getCaseRelations(event.caseCode);
      emit(CaseRelationsLoaded(relations));
    } catch (e) {
      emit(CaseRelationsError(e.toString()));
    }
  }
}
