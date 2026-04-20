import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/client_portal_repository.dart';
import 'client_portal_event.dart';
import 'client_portal_state.dart';

class ClientPortalBloc extends Bloc<ClientPortalEvent, ClientPortalState> {
  final ClientPortalRepository clientPortalRepository;

  ClientPortalBloc({required this.clientPortalRepository}) : super(ClientPortalInitial()) {
    on<LoadPortalMessages>(_onLoadPortalMessages);
    on<RefreshPortalMessages>(_onRefreshPortalMessages);
    on<SearchPortalMessages>(_onSearchPortalMessages);
    on<SelectPortalMessage>(_onSelectPortalMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<LoadPortalDocuments>(_onLoadPortalDocuments);
    on<RefreshPortalDocuments>(_onRefreshPortalDocuments);
    on<SendPortalMessage>(_onSendMessage);
    on<DownloadPortalDocument>(_onDownloadDocument);
    on<UploadPortalDocument>(_onUploadDocument);
  }

  Future<void> _onLoadPortalMessages(LoadPortalMessages event, Emitter<ClientPortalState> emit) async {
    emit(ClientPortalLoading());
    try {
      final messages = await clientPortalRepository.getMessages();
      emit(ClientPortalMessagesLoaded(messages));
    } catch (e) {
      emit(ClientPortalError(e.toString()));
    }
  }

  Future<void> _onRefreshPortalMessages(RefreshPortalMessages event, Emitter<ClientPortalState> emit) async {
    try {
      final messages = await clientPortalRepository.getMessages();
      emit(ClientPortalMessagesLoaded(messages));
    } catch (e) {
      emit(ClientPortalError(e.toString()));
    }
  }

  Future<void> _onSearchPortalMessages(SearchPortalMessages event, Emitter<ClientPortalState> emit) async {
    emit(ClientPortalLoading());
    try {
      final allMessages = await clientPortalRepository.getMessages();
      final filtered = allMessages.where((m) => m.subject.toLowerCase().contains(event.query.toLowerCase()) || m.body.toLowerCase().contains(event.query.toLowerCase())).toList();
      emit(ClientPortalMessagesLoaded(filtered));
    } catch (e) {
      emit(ClientPortalError(e.toString()));
    }
  }

  Future<void> _onSelectPortalMessage(SelectPortalMessage event, Emitter<ClientPortalState> emit) async {
    emit(PortalMessageSelected(event.message));
  }

  Future<void> _onMarkMessageAsRead(MarkMessageAsRead event, Emitter<ClientPortalState> emit) async {
    try {
      await clientPortalRepository.markMessageAsRead(event.messageId);
      emit(PortalMessageMarkedAsRead(event.messageId));
    } catch (e) {
      emit(ClientPortalError(e.toString()));
    }
  }

  Future<void> _onLoadPortalDocuments(LoadPortalDocuments event, Emitter<ClientPortalState> emit) async {
    emit(ClientPortalLoading());
    try {
      final docs = await clientPortalRepository.getDocuments();
      emit(ClientPortalDocumentsLoaded(docs));
    } catch (e) {
      emit(ClientPortalError(e.toString()));
    }
  }

  Future<void> _onRefreshPortalDocuments(RefreshPortalDocuments event, Emitter<ClientPortalState> emit) async {
    try {
      final docs = await clientPortalRepository.getDocuments();
      emit(ClientPortalDocumentsLoaded(docs));
    } catch (e) {
      emit(ClientPortalError(e.toString()));
    }
  }

  Future<void> _onSendMessage(SendPortalMessage event, Emitter<ClientPortalState> emit) async {
    emit(ClientPortalLoading());
    try {
      await clientPortalRepository.sendMessage(event.subject, event.body);
      emit(PortalMessageSent());
      final messages = await clientPortalRepository.getMessages();
      emit(ClientPortalMessagesLoaded(messages));
    } catch (e) {
      emit(ClientPortalError(e.toString()));
    }
  }

  Future<void> _onDownloadDocument(DownloadPortalDocument event, Emitter<ClientPortalState> emit) async {
    try {
      final url = await clientPortalRepository.getDocumentDownloadUrl(event.messageId);
      if (url != null && url.isNotEmpty) {
        emit(PortalDocumentUrlReady(url));
      } else {
        emit(ClientPortalError('Download URL not available'));
      }
    } catch (e) {
      emit(ClientPortalError(e.toString()));
    }
  }

  Future<void> _onUploadDocument(UploadPortalDocument event, Emitter<ClientPortalState> emit) async {
    emit(PortalDocumentUploading());
    try {
      await clientPortalRepository.uploadPortalDocument(event.filePath, title: event.title);
      emit(PortalDocumentUploaded());
      emit(ClientPortalDocumentsLoaded(await clientPortalRepository.getDocuments()));
    } catch (e) {
      emit(ClientPortalError(e.toString()));
    }
  }
}
