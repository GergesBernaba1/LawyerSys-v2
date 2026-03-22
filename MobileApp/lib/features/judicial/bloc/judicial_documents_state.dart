import '../models/judicial_document.dart';

abstract class JudicialDocumentsState {}

class JudicialDocumentsInitial extends JudicialDocumentsState {}

class JudicialDocumentsLoading extends JudicialDocumentsState {}

class JudicialDocumentsLoaded extends JudicialDocumentsState {
  final List<JudicialDocument> documents;
  final int totalCount;
  final int page;
  final String? search;

  JudicialDocumentsLoaded({
    required this.documents,
    required this.totalCount,
    required this.page,
    this.search,
  });
}

class JudicialDocumentsError extends JudicialDocumentsState {
  final String message;
  JudicialDocumentsError(this.message);
}

class JudicialDocumentActionSuccess extends JudicialDocumentsState {
  final String message;
  JudicialDocumentActionSuccess(this.message);
}
