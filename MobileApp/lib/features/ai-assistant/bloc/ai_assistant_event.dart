abstract class AiAssistantEvent {}

class SummarizeText extends AiAssistantEvent {

  SummarizeText(this.text, {this.language});
  final String text;
  final String? language;
}

class DraftDocument extends AiAssistantEvent {

  DraftDocument(this.prompt, {this.documentType, this.language});
  final String prompt;
  final String? documentType;
  final String? language;
}

class LoadDeadlineSuggestions extends AiAssistantEvent {}
