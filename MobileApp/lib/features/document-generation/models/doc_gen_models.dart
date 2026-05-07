class DocTemplateField { // for select type

  DocTemplateField({
    required this.key,
    required this.label,
    required this.fieldType,
    required this.required,
    this.options,
  });

  factory DocTemplateField.fromJson(Map<String, dynamic> json) {
    return DocTemplateField(
      key: json['key'] as String,
      label: json['label'] as String,
      fieldType: json['fieldType'] as String? ?? 'text',
      required: json['required'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
  final String key;
  final String label;
  final String fieldType; // text, date, number, select
  final bool required;
  final List<String>? options;
}

class DocTemplate {

  DocTemplate({
    required this.id,
    required this.name,
    this.description,
    this.language,
    required this.fields,
  });

  factory DocTemplate.fromJson(Map<String, dynamic> json) {
    return DocTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      language: json['language'] as String?,
      fields: (json['fields'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DocTemplateField.fromJson)
          .toList(),
    );
  }
  final String id;
  final String name;
  final String? description;
  final String? language;
  final List<DocTemplateField> fields;
}

class GeneratedDoc {

  GeneratedDoc({
    required this.id,
    required this.title,
    required this.generatedAt,
    this.templateName,
    this.caseCode,
  });

  factory GeneratedDoc.fromJson(Map<String, dynamic> json) {
    return GeneratedDoc(
      id: json['id'] as String,
      title: json['title'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      templateName: json['templateName'] as String?,
      caseCode: json['caseCode'] as String?,
    );
  }
  final String id;
  final String title;
  final DateTime generatedAt;
  final String? templateName;
  final String? caseCode;
}

class DocDraft {

  DocDraft({
    required this.id,
    required this.title,
    this.content,
    required this.createdAt,
  });

  factory DocDraft.fromJson(Map<String, dynamic> json) {
    return DocDraft(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  final String id;
  final String title;
  final String? content;
  final DateTime createdAt;
}
