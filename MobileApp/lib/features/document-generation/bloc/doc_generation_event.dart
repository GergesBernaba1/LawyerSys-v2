abstract class DocGenerationEvent {}

class LoadDocTemplates extends DocGenerationEvent {
  final String? language;
  LoadDocTemplates({this.language});
}

class GenerateDocument extends DocGenerationEvent {
  final String templateId;
  final Map<String, dynamic> fieldValues;
  final String? language;
  final String? caseCode;

  GenerateDocument({
    required this.templateId,
    required this.fieldValues,
    this.language,
    this.caseCode,
  });
}

class LoadDocHistory extends DocGenerationEvent {
  final String? caseCode;
  LoadDocHistory({this.caseCode});
}

class LoadDocDrafts extends DocGenerationEvent {}

class CreateDocDraft extends DocGenerationEvent {
  final String title;
  final String content;
  final String? templateId;

  CreateDocDraft({
    required this.title,
    required this.content,
    this.templateId,
  });
}

class DeleteDocDraft extends DocGenerationEvent {
  final String id;
  DeleteDocDraft(this.id);
}
