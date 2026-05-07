abstract class JudicialDocumentsEvent {}

class LoadJudicialDocuments extends JudicialDocumentsEvent {
  LoadJudicialDocuments({this.page = 1, this.search});
  final int page;
  final String? search;
}

class RefreshJudicialDocuments extends JudicialDocumentsEvent {}

class SearchJudicialDocuments extends JudicialDocumentsEvent {
  SearchJudicialDocuments(this.query);
  final String query;
}

class CreateJudicialDocument extends JudicialDocumentsEvent {
  CreateJudicialDocument(this.payload);
  final Map<String, dynamic> payload;
}

class UpdateJudicialDocument extends JudicialDocumentsEvent {
  UpdateJudicialDocument(this.id, this.payload);
  final int id;
  final Map<String, dynamic> payload;
}

class DeleteJudicialDocument extends JudicialDocumentsEvent {
  DeleteJudicialDocument(this.id);
  final int id;
}
