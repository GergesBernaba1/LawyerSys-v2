import 'package:qadaya_lawyersys/features/document-generation/models/doc_gen_models.dart';

abstract class DocGenState {}

class DocGenInitial extends DocGenState {}

class DocGenLoading extends DocGenState {}

class DocTemplatesLoaded extends DocGenState {
  DocTemplatesLoaded(this.templates);
  final List<DocTemplate> templates;
}

class DocGeneratedSuccess extends DocGenState {
  DocGeneratedSuccess(this.doc);
  final GeneratedDoc doc;
}

class DocHistoryLoaded extends DocGenState {
  DocHistoryLoaded(this.history);
  final List<GeneratedDoc> history;
}

class DocDraftsLoaded extends DocGenState {
  DocDraftsLoaded(this.drafts);
  final List<DocDraft> drafts;
}

class DocGenOperationSuccess extends DocGenState {
  DocGenOperationSuccess(this.message);
  final String message;
}

class DocGenError extends DocGenState {
  DocGenError(this.message);
  final String message;
}
