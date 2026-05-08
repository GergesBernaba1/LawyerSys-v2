abstract class DocGenerationEvent {}

class LoadDocTemplates extends DocGenerationEvent {
  LoadDocTemplates({this.language});
  final String? language;
}

class GenerateDocument extends DocGenerationEvent {

  GenerateDocument({
    required this.templateId,
    required this.fieldValues,
    this.language,
    this.caseCode,
    this.title,
    this.reference,
    this.category,
    this.notes,
    this.aiInstructions,
    this.exportFormat,
  });
  final String templateId;
  final Map<String, dynamic> fieldValues;
  final String? language;
  final String? caseCode;
  final String? title;
  final String? reference;
  final String? category;
  final String? notes;
  final String? aiInstructions;
  final String? exportFormat;
}

class LoadDocHistory extends DocGenerationEvent {
  LoadDocHistory({this.caseCode});
  final String? caseCode;
}

class LoadDocDrafts extends DocGenerationEvent {}

class CreateDocDraft extends DocGenerationEvent {

  CreateDocDraft({
    required this.title,
    required this.content,
    this.templateId,
  });
  final String title;
  final String content;
  final String? templateId;
}

class DeleteDocDraft extends DocGenerationEvent {
  DeleteDocDraft(this.id);
  final String id;
}
