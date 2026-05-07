import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/documents/bloc/documents_event.dart';
import 'package:qadaya_lawyersys/features/documents/bloc/documents_state.dart';
import 'package:qadaya_lawyersys/features/documents/repositories/documents_repository.dart';

class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {

  DocumentsBloc({required this.documentsRepository}) : super(DocumentsInitial()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<LoadMoreDocuments>(_onLoadMoreDocuments);
    on<DownloadDocument>(_onDownloadDocument);
    on<RefreshDocuments>(_onRefreshDocuments);
    on<UploadDocument>(_onUploadDocument);
    on<ShareDocument>(_onShare);
    on<RenameDocument>(_onRename);
  }
  final DocumentsRepository documentsRepository;
  final List<dynamic> _documents = [];
  static const int _pageSize = 20;

  Future<void> _onLoadDocuments(LoadDocuments event, Emitter<DocumentsState> emit) async {
    emit(DocumentsLoading());
    try {
      final docs = await documentsRepository.getDocuments(
        search: event.search,
      );
      _documents
        ..clear()
        ..addAll(docs);
      emit(DocumentsLoaded(
        docs,
        hasMore: docs.length >= _pageSize,
      ),);
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> _onLoadMoreDocuments(
      LoadMoreDocuments event, Emitter<DocumentsState> emit,) async {
    final currentState = state;
    if (currentState is! DocumentsLoaded || 
        currentState.isLoadingMore || 
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));
    
    try {
      final nextPage = currentState.currentPage + 1;
      final newDocs = await documentsRepository.getDocuments(
        page: nextPage,
      );
      
      _documents.addAll(newDocs);
      
      emit(DocumentsLoaded(
        List.from(_documents),
        currentPage: nextPage,
        hasMore: newDocs.length >= _pageSize,
      ),);
    } catch (e) {
      emit(currentState.copyWith(isLoadingMore: false));
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> _onRefreshDocuments(RefreshDocuments event, Emitter<DocumentsState> emit) async {
    if (!isClosed) add(LoadDocuments());
  }

  Future<void> _onDownloadDocument(DownloadDocument event, Emitter<DocumentsState> emit) async {
    emit(DocumentsDownloading('Downloading ${event.document.fileName}...'));
    try {
      await documentsRepository.downloadDocument(event.document);
      final docs = await documentsRepository.getDocuments();
      _documents
        ..clear()
        ..addAll(docs);
      emit(DocumentsLoaded(
        docs,
        hasMore: docs.length >= _pageSize,
      ),);
    } catch (e) {
      emit(DocumentsError('Failed to download: ${e.toString()}'));
    }
  }

  Future<void> _onUploadDocument(UploadDocument event, Emitter<DocumentsState> emit) async {
    emit(DocumentsUploading());
    try {
      await documentsRepository.uploadDocument(
        event.filePath,
        title: event.title,
        description: event.description,
      );
      emit(DocumentsUploadSuccess());
      final docs = await documentsRepository.getDocuments();
      _documents
        ..clear()
        ..addAll(docs);
      emit(DocumentsLoaded(
        docs,
        hasMore: docs.length >= _pageSize,
      ),);
    } catch (e) {
      emit(DocumentsError('Failed to upload: ${e.toString()}'));
    }
  }

  Future<void> _onShare(ShareDocument event, Emitter<DocumentsState> emit) async {
    try {
      final url = await documentsRepository.getShareLink(event.documentId);
      if (url != null) {
        emit(DocumentShareLinkLoaded(url));
      } else {
        emit(DocumentsError('No share link available'));
      }
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> _onRename(RenameDocument event, Emitter<DocumentsState> emit) async {
    try {
      await documentsRepository.renameDocument(event.documentId, event.newName);
      emit(DocumentRenamed());
      final docs = await documentsRepository.getDocuments();
      _documents
        ..clear()
        ..addAll(docs);
      emit(DocumentsLoaded(
        docs,
        hasMore: docs.length >= _pageSize,
      ),);
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }
}
