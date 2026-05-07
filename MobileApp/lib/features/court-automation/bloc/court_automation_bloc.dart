import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/court-automation/bloc/court_automation_event.dart';
import 'package:qadaya_lawyersys/features/court-automation/bloc/court_automation_state.dart';
import 'package:qadaya_lawyersys/features/court-automation/repositories/court_automation_repository.dart';

class CourtAutomationBloc
    extends Bloc<CourtAutomationEvent, CourtAutoState> {

  CourtAutomationBloc({required this.repository}) : super(CourtAutoInitial()) {
    on<LoadAutomationPacks>(_onLoadAutomationPacks);
    on<CalculateDeadlines>(_onCalculateDeadlines);
    on<SubmitFiling>(_onSubmitFiling);
    on<LoadFilings>(_onLoadFilings);
  }
  final CourtAutomationRepository repository;

  Future<void> _onLoadAutomationPacks(
      LoadAutomationPacks event, Emitter<CourtAutoState> emit,) async {
    emit(CourtAutoLoading());
    try {
      final packs = await repository.getPacks(language: event.language);
      emit(AutomationPacksLoaded(packs));
    } catch (e) {
      emit(CourtAutoError(e.toString()));
    }
  }

  Future<void> _onCalculateDeadlines(
      CalculateDeadlines event, Emitter<CourtAutoState> emit,) async {
    emit(CourtAutoLoading());
    try {
      final deadlines = await repository.calculateDeadlines(
        packKey: event.packKey,
        filingDate: event.filingDate,
      );
      emit(DeadlinesCalculated(deadlines, packKey: event.packKey));
    } catch (e) {
      emit(CourtAutoError(e.toString()));
    }
  }

  Future<void> _onSubmitFiling(
      SubmitFiling event, Emitter<CourtAutoState> emit,) async {
    emit(CourtAutoLoading());
    try {
      final submission = await repository.submitFiling(
        caseCode: event.caseCode,
        packKey: event.packKey,
        formData: event.formData,
      );
      emit(FilingSubmitted(submission));
    } catch (e) {
      emit(CourtAutoError(e.toString()));
    }
  }

  Future<void> _onLoadFilings(
      LoadFilings event, Emitter<CourtAutoState> emit,) async {
    emit(CourtAutoLoading());
    try {
      final filings = await repository.getFilings(caseCode: event.caseCode);
      emit(FilingsLoaded(filings));
    } catch (e) {
      emit(CourtAutoError(e.toString()));
    }
  }
}
