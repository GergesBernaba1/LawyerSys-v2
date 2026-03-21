import '../models/document.dart';

abstract class DocumentsEvent {}

class LoadDocuments extends DocumentsEvent {
  final String? search;
  LoadDocuments({this.search});
}

class DownloadDocument extends DocumentsEvent {
  final Document document;
  DownloadDocument(this.document);
}

class RefreshDocuments extends DocumentsEvent {}
