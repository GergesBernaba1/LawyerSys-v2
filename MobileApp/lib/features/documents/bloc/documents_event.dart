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

class UploadDocument extends DocumentsEvent {
  final String filePath;
  final String? title;
  final String? description;
  UploadDocument(this.filePath, {this.title, this.description});
}

class ShareDocument extends DocumentsEvent {
  final int documentId;
  ShareDocument(this.documentId);
}

class RenameDocument extends DocumentsEvent {
  final int documentId;
  final String newName;
  RenameDocument({required this.documentId, required this.newName});
}
