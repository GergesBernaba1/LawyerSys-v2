import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/ai-assistant/bloc/ai_assistant_event.dart';
import 'package:qadaya_lawyersys/features/ai-assistant/bloc/ai_assistant_state.dart';
import 'package:qadaya_lawyersys/features/ai-assistant/repositories/ai_assistant_repository.dart';

class AiAssistantBloc extends Bloc<AiAssistantEvent, AiAssistantState> {

  AiAssistantBloc({required this.repository}) : super(AiAssistantInitial()) {
    on<SummarizeText>(_onSummarizeText);
    on<DraftDocument>(_onDraftDocument);
    on<LoadDeadlineSuggestions>(_onLoadDeadlineSuggestions);
  }
  final AiAssistantRepository repository;

  Future<void> _onSummarizeText(
    SummarizeText event,
    Emitter<AiAssistantState> emit,
  ) async {
    emit(AiAssistantLoading());
    try {
      final result = await repository.summarize(
        event.text,
        language: event.language,
      );
      emit(AiSummaryLoaded(result.summary));
    } catch (e) {
      emit(AiAssistantError(e.toString()));
    }
  }

  Future<void> _onDraftDocument(
    DraftDocument event,
    Emitter<AiAssistantState> emit,
  ) async {
    emit(AiAssistantLoading());
    try {
      final result = await repository.draft(
        event.prompt,
        documentType: event.documentType,
        language: event.language,
      );
      emit(AiDraftLoaded(result.content, result.documentType));
    } catch (e) {
      emit(AiAssistantError(e.toString()));
    }
  }

  Future<void> _onLoadDeadlineSuggestions(
    LoadDeadlineSuggestions event,
    Emitter<AiAssistantState> emit,
  ) async {
    emit(AiAssistantLoading());
    try {
      final suggestions = await repository.getDeadlineSuggestions();
      emit(AiDeadlineSuggestionsLoaded(suggestions));
    } catch (e) {
      emit(AiAssistantError(e.toString()));
    }
  }
}
