import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/intake_repository.dart';
import '../models/intake_form.dart';
import 'intake_event.dart';
import 'intake_state.dart';

class IntakeBloc extends Bloc<IntakeEvent, IntakeState> {
  final IntakeRepository repository;

  IntakeBloc({required this.repository}) : super(IntakeInitial()) {
    on<LoadIntakeLeads>(_onLoad);
    on<RefreshIntakeLeads>(_onRefresh);
    on<SearchIntakeLeads>(_onSearch);
    on<FilterIntakeByStatus>(_onFilterStatus);
    on<RunIntakeConflictCheck>(_onConflictCheck);
    on<QualifyIntakeLead>(_onQualify);
    on<AssignIntakeLead>(_onAssign);
    on<ConvertIntakeLead>(_onConvert);
    on<CreatePublicIntakeLead>(_onCreatePublic);
  }

  Future<void> _onLoad(LoadIntakeLeads event, Emitter<IntakeState> emit) async {
    emit(IntakeLoading());
    try {
      final results = await Future.wait([
        repository.getLeads(status: event.status, search: event.search),
        repository.getAssignmentOptions(),
      ]);
      emit(IntakeLoaded(
        leads: results[0] as List<IntakeForm>,
        assignmentOptions: results[1] as List<IntakeAssignmentOption>,
        activeStatus: event.status,
        activeSearch: event.search,
      ));
    } catch (e) {
      emit(IntakeError(e.toString()));
    }
  }

  Future<void> _onRefresh(
      RefreshIntakeLeads event, Emitter<IntakeState> emit) async {
    final current = state is IntakeLoaded ? state as IntakeLoaded : null;
    try {
      final leads = await repository.getLeads(
        status: current?.activeStatus,
        search: current?.activeSearch,
      );
      if (current != null) {
        emit(current.copyWith(leads: leads));
      } else {
        emit(IntakeLoaded(leads: leads));
      }
    } catch (e) {
      emit(IntakeError(e.toString()));
    }
  }

  Future<void> _onSearch(
      SearchIntakeLeads event, Emitter<IntakeState> emit) async {
    final current = state is IntakeLoaded ? state as IntakeLoaded : null;
    emit(IntakeLoading());
    try {
      final leads = await repository.getLeads(
        status: current?.activeStatus,
        search: event.query.isEmpty ? null : event.query,
      );
      emit(IntakeLoaded(
        leads: leads,
        assignmentOptions: current?.assignmentOptions ?? [],
        activeStatus: current?.activeStatus,
        activeSearch: event.query.isEmpty ? null : event.query,
      ));
    } catch (e) {
      emit(IntakeError(e.toString()));
    }
  }

  Future<void> _onFilterStatus(
      FilterIntakeByStatus event, Emitter<IntakeState> emit) async {
    final current = state is IntakeLoaded ? state as IntakeLoaded : null;
    emit(IntakeLoading());
    try {
      final leads = await repository.getLeads(
        status: event.status,
        search: current?.activeSearch,
      );
      emit(IntakeLoaded(
        leads: leads,
        assignmentOptions: current?.assignmentOptions ?? [],
        activeStatus: event.status,
        activeSearch: current?.activeSearch,
      ));
    } catch (e) {
      emit(IntakeError(e.toString()));
    }
  }

  Future<void> _onConflictCheck(
      RunIntakeConflictCheck event, Emitter<IntakeState> emit) async {
    try {
      await repository.runConflictCheck(event.id);
      emit(IntakeActionSuccess('Conflict check complete'));
      if (!isClosed) add(RefreshIntakeLeads());
    } catch (e) {
      emit(IntakeError(e.toString()));
    }
  }

  Future<void> _onQualify(
      QualifyIntakeLead event, Emitter<IntakeState> emit) async {
    try {
      await repository.qualify(event.id,
          isQualified: event.isQualified, notes: event.notes);
      emit(IntakeActionSuccess(
          event.isQualified ? 'Lead qualified' : 'Lead rejected'));
      if (!isClosed) add(RefreshIntakeLeads());
    } catch (e) {
      emit(IntakeError(e.toString()));
    }
  }

  Future<void> _onAssign(
      AssignIntakeLead event, Emitter<IntakeState> emit) async {
    try {
      await repository.assign(event.id,
          assignedEmployeeId: event.assignedEmployeeId,
          nextFollowUpAt: event.nextFollowUpAt);
      emit(IntakeActionSuccess('Lead assigned'));
      if (!isClosed) add(RefreshIntakeLeads());
    } catch (e) {
      emit(IntakeError(e.toString()));
    }
  }

  Future<void> _onConvert(
      ConvertIntakeLead event, Emitter<IntakeState> emit) async {
    try {
      await repository.convert(event.id,
          caseType: event.caseType, initialAmount: event.initialAmount);
      emit(IntakeActionSuccess('Lead converted to customer and case'));
      if (!isClosed) add(RefreshIntakeLeads());
    } catch (e) {
      emit(IntakeError(e.toString()));
    }
  }

  Future<void> _onCreatePublic(
      CreatePublicIntakeLead event, Emitter<IntakeState> emit) async {
    try {
      await repository.createPublicLead(event.payload);
      emit(IntakeActionSuccess('Intake submitted successfully'));
    } catch (e) {
      emit(IntakeError(e.toString()));
    }
  }
}
