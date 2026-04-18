import '../models/ai_models.dart';

abstract class AiAssistantState {}

class AiAssistantInitial extends AiAssistantState {}

class AiAssistantLoading extends AiAssistantState {}

class AiSummaryLoaded extends AiAssistantState {
  final String summary;
  AiSummaryLoaded(this.summary);
}

class AiDraftLoaded extends AiAssistantState {
  final String content;
  final String? documentType;
  AiDraftLoaded(this.content, this.documentType);
}

class AiDeadlineSuggestionsLoaded extends AiAssistantState {
  final List<AiDeadlineSuggestion> suggestions;
  AiDeadlineSuggestionsLoaded(this.suggestions);
}

class AiAssistantError extends AiAssistantState {
  final String message;
  AiAssistantError(this.message);
}
