import '../models/doc_gen_models.dart';

abstract class DocGenState {}

class DocGenInitial extends DocGenState {}

class DocGenLoading extends DocGenState {}

class DocTemplatesLoaded extends DocGenState {
  final List<DocTemplate> templates;
  DocTemplatesLoaded(this.templates);
}

class DocGeneratedSuccess extends DocGenState {
  final GeneratedDoc doc;
  DocGeneratedSuccess(this.doc);
}

class DocHistoryLoaded extends DocGenState {
  final List<GeneratedDoc> history;
  DocHistoryLoaded(this.history);
}

class DocDraftsLoaded extends DocGenState {
  final List<DocDraft> drafts;
  DocDraftsLoaded(this.drafts);
}

class DocGenOperationSuccess extends DocGenState {
  final String message;
  DocGenOperationSuccess(this.message);
}

class DocGenError extends DocGenState {
  final String message;
  DocGenError(this.message);
}
