import 'package:qadaya_lawyersys/features/judicial/models/judicial_document.dart';

abstract class JudicialDocumentsState {}

class JudicialDocumentsInitial extends JudicialDocumentsState {}

class JudicialDocumentsLoading extends JudicialDocumentsState {}

class JudicialDocumentsLoaded extends JudicialDocumentsState {

  JudicialDocumentsLoaded({
    required this.documents,
    required this.totalCount,
    required this.page,
    this.search,
  });
  final List<JudicialDocument> documents;
  final int totalCount;
  final int page;
  final String? search;
}

class JudicialDocumentsError extends JudicialDocumentsState {
  JudicialDocumentsError(this.message);
  final String message;
}

class JudicialDocumentActionSuccess extends JudicialDocumentsState {
  JudicialDocumentActionSuccess(this.message);
  final String message;
}
