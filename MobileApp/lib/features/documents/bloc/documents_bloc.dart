import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/documents_repository.dart';
import 'documents_event.dart';
import 'documents_state.dart';

class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final DocumentsRepository documentsRepository;

  DocumentsBloc({required this.documentsRepository}) : super(DocumentsInitial()) {
    on<LoadDocuments>(_onLoadDocuments);
    on<DownloadDocument>(_onDownloadDocument);
    on<RefreshDocuments>(_onRefreshDocuments);
    on<UploadDocument>(_onUploadDocument);
    on<ShareDocument>(_onShare);
    on<RenameDocument>(_onRename);
  }

  Future<void> _onLoadDocuments(LoadDocuments event, Emitter<DocumentsState> emit) async {
    emit(DocumentsLoading());
    try {
      final docs = await documentsRepository.getDocuments(search: event.search);
      emit(DocumentsLoaded(docs));
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }

  Future<void> _onRefreshDocuments(RefreshDocuments event, Emitter<DocumentsState> emit) async {
    add(LoadDocuments());
  }

  Future<void> _onDownloadDocument(DownloadDocument event, Emitter<DocumentsState> emit) async {
    emit(DocumentsDownloading('Downloading ${event.document.fileName}...'));
    try {
      await documentsRepository.downloadDocument(event.document);
      emit(DocumentsLoaded(await documentsRepository.getDocuments()));
      // Keep state as loaded after download; notice Users can open from storage.
      emit(DocumentsLoaded(await documentsRepository.getDocuments()));
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
      emit(DocumentsLoaded(docs));
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
      emit(DocumentsLoaded(docs));
    } catch (e) {
      emit(DocumentsError(e.toString()));
    }
  }
}
