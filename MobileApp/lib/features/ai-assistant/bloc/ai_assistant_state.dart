import 'package:qadaya_lawyersys/features/ai-assistant/models/ai_models.dart';

abstract class AiAssistantState {}

class AiAssistantInitial extends AiAssistantState {}

class AiAssistantLoading extends AiAssistantState {}

class AiSummaryLoaded extends AiAssistantState {
  AiSummaryLoaded(this.summary);
  final String summary;
}

class AiDraftLoaded extends AiAssistantState {
  AiDraftLoaded(this.content, this.documentType);
  final String content;
  final String? documentType;
}

class AiDeadlineSuggestionsLoaded extends AiAssistantState {
  AiDeadlineSuggestionsLoaded(this.suggestions);
  final List<AiDeadlineSuggestion> suggestions;
}

class AiAssistantError extends AiAssistantState {
  AiAssistantError(this.message);
  final String message;
}
