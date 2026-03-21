import '../models/judicial_document.dart';

abstract class JudicialDocumentsEvent {}

class LoadJudicialDocuments extends JudicialDocumentsEvent {
  final int page;
  final String? search;
  LoadJudicialDocuments({this.page = 1, this.search});
}

class RefreshJudicialDocuments extends JudicialDocumentsEvent {}

class SearchJudicialDocuments extends JudicialDocumentsEvent {
  final String query;
  SearchJudicialDocuments(this.query);
}

class CreateJudicialDocument extends JudicialDocumentsEvent {
  final Map<String, dynamic> payload;
  CreateJudicialDocument(this.payload);
}

class UpdateJudicialDocument extends JudicialDocumentsEvent {
  final int id;
  final Map<String, dynamic> payload;
  UpdateJudicialDocument(this.id, this.payload);
}

class DeleteJudicialDocument extends JudicialDocumentsEvent {
  final int id;
  DeleteJudicialDocument(this.id);
}
