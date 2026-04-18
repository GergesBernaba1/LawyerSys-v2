abstract class AiAssistantEvent {}

class SummarizeText extends AiAssistantEvent {
  final String text;
  final String? language;

  SummarizeText(this.text, {this.language});
}

class DraftDocument extends AiAssistantEvent {
  final String prompt;
  final String? documentType;
  final String? language;

  DraftDocument(this.prompt, {this.documentType, this.language});
}

class LoadDeadlineSuggestions extends AiAssistantEvent {}
