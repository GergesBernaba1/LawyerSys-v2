class AiSummaryRequest {
  final String text;
  final String? language;

  AiSummaryRequest({required this.text, this.language});

  Map<String, dynamic> toJson() => {
        'text': text,
        if (language != null) 'language': language,
      };
}

class AiSummaryResult {
  final String summary;

  AiSummaryResult({required this.summary});

  factory AiSummaryResult.fromJson(Map<String, dynamic> json) {
    return AiSummaryResult(
      summary: (json['summary'] ?? json['result'] ?? '').toString(),
    );
  }
}

class AiDraftRequest {
  final String prompt;
  final String? documentType;
  final String? language;

  AiDraftRequest({required this.prompt, this.documentType, this.language});

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        if (documentType != null) 'documentType': documentType,
        if (language != null) 'language': language,
      };
}

class AiDraftResult {
  final String content;
  final String? documentType;

  AiDraftResult({required this.content, this.documentType});

  factory AiDraftResult.fromJson(Map<String, dynamic> json) {
    return AiDraftResult(
      content: (json['content'] ?? json['result'] ?? '').toString(),
      documentType: json['documentType']?.toString(),
    );
  }
}

class AiDeadlineSuggestion {
  final String taskName;
  final String? suggestedDeadline;
  final String? reason;

  AiDeadlineSuggestion({
    required this.taskName,
    this.suggestedDeadline,
    this.reason,
  });

  factory AiDeadlineSuggestion.fromJson(Map<String, dynamic> json) {
    return AiDeadlineSuggestion(
      taskName: (json['taskName'] ?? json['task'] ?? '').toString(),
      suggestedDeadline: json['suggestedDeadline']?.toString(),
      reason: json['reason']?.toString(),
    );
  }
}
