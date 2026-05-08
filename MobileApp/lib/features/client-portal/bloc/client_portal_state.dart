import 'package:qadaya_lawyersys/features/client-portal/models/portal_message.dart';

abstract class ClientPortalState {}

class ClientPortalInitial extends ClientPortalState {}
class ClientPortalLoading extends ClientPortalState {}

class ClientPortalMessagesLoaded extends ClientPortalState {
  ClientPortalMessagesLoaded(this.messages);
  final List<PortalMessageModel> messages;
}

class ClientPortalDocumentsLoaded extends ClientPortalState {
  ClientPortalDocumentsLoaded(this.documents);
  final List<PortalMessageModel> documents;
}

class ClientPortalError extends ClientPortalState {
  ClientPortalError(this.message);
  final String message;
}

class PortalMessageSelected extends ClientPortalState {
  PortalMessageSelected(this.message);
  final PortalMessageModel message;
}

class PortalMessageMarkedAsRead extends ClientPortalState {
  PortalMessageMarkedAsRead(this.messageId);
  final String messageId;
}

class PortalMessageSent extends ClientPortalState {}

class PortalDocumentUrlReady extends ClientPortalState {
  PortalDocumentUrlReady(this.url);
  final String url;
}

class PortalDocumentUploading extends ClientPortalState {}
class PortalDocumentUploaded extends ClientPortalState {}

class PortalOverviewLoaded extends ClientPortalState {
  PortalOverviewLoaded(this.data);
  final Map<String, dynamic> data;
}
