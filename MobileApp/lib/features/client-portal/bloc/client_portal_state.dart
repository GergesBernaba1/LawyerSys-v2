import '../models/portal_message.dart';

abstract class ClientPortalState {}

class ClientPortalInitial extends ClientPortalState {}
class ClientPortalLoading extends ClientPortalState {}

class ClientPortalMessagesLoaded extends ClientPortalState {
  final List<PortalMessageModel> messages;
  ClientPortalMessagesLoaded(this.messages);
}

class ClientPortalDocumentsLoaded extends ClientPortalState {
  final List<PortalMessageModel> documents;
  ClientPortalDocumentsLoaded(this.documents);
}

class ClientPortalError extends ClientPortalState {
  final String message;
  ClientPortalError(this.message);
}

class PortalMessageSelected extends ClientPortalState {
  final PortalMessageModel message;
  PortalMessageSelected(this.message);
}

class PortalMessageMarkedAsRead extends ClientPortalState {
  final String messageId;
  PortalMessageMarkedAsRead(this.messageId);
}

class PortalMessageSent extends ClientPortalState {}

class PortalDocumentUrlReady extends ClientPortalState {
  final String url;
  PortalDocumentUrlReady(this.url);
}
