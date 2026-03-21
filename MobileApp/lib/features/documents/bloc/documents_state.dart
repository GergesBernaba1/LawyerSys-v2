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
