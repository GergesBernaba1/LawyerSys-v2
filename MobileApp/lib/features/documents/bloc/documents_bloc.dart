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
}
