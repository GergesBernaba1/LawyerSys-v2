import 'package:qadaya_lawyersys/features/documents/models/document.dart';

abstract class DocumentsEvent {}

class LoadDocuments extends DocumentsEvent {
  LoadDocuments({this.search});
  final String? search;
}

class LoadMoreDocuments extends DocumentsEvent {}

class DownloadDocument extends DocumentsEvent {
  DownloadDocument(this.document);
  final Document document;
}

class RefreshDocuments extends DocumentsEvent {}

class UploadDocument extends DocumentsEvent {
  UploadDocument(this.filePath, {this.title, this.description});
  final String filePath;
  final String? title;
  final String? description;
}

class ShareDocument extends DocumentsEvent {
  ShareDocument(this.documentId);
  final int documentId;
}

class RenameDocument extends DocumentsEvent {
  RenameDocument({required this.documentId, required this.newName});
  final int documentId;
  final String newName;
}
