import 'package:qadaya_lawyersys/features/documents/models/document.dart';

abstract class DocumentsState {}

class DocumentsInitial extends DocumentsState {}

class DocumentsLoading extends DocumentsState {}

class DocumentsLoaded extends DocumentsState {
  
  DocumentsLoaded(
    this.documents, {
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });
  final List<Document> documents;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  DocumentsLoaded copyWith({
    List<Document>? documents,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return DocumentsLoaded(
      documents ?? this.documents,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class DocumentsDownloading extends DocumentsState {
  DocumentsDownloading(this.message);
  final String message;
}

class DocumentsError extends DocumentsState {
  DocumentsError(this.error);
  final String error;
}

class DocumentsUploading extends DocumentsState {}

class DocumentsUploadSuccess extends DocumentsState {}

class DocumentShareLinkLoaded extends DocumentsState {
  DocumentShareLinkLoaded(this.url);
  final String url;
}

class DocumentRenamed extends DocumentsState {}
