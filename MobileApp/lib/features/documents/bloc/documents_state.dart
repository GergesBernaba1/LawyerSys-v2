import '../models/document.dart';

abstract class DocumentsState {}

class DocumentsInitial extends DocumentsState {}

class DocumentsLoading extends DocumentsState {}

class DocumentsLoaded extends DocumentsState {
  final List<Document> documents;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  
  DocumentsLoaded(
    this.documents, {
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

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
