import '../models/document.dart';

abstract class DocumentsState {}

class DocumentsInitial extends DocumentsState {}

class DocumentsLoading extends DocumentsState {}

class DocumentsLoaded extends DocumentsState {
  final List<Document> documents;
  DocumentsLoaded(this.documents);
}

class DocumentsDownloading extends DocumentsState {
  final String message;
  DocumentsDownloading(this.message);
}

class DocumentsError extends DocumentsState {
  final String error;
  DocumentsError(this.error);
}

class DocumentsUploading extends DocumentsState {}

class DocumentsUploadSuccess extends DocumentsState {}

class DocumentShareLinkLoaded extends DocumentsState {
  final String url;
  DocumentShareLinkLoaded(this.url);
}

class DocumentRenamed extends DocumentsState {}
