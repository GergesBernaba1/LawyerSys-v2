import '../models/portal_message.dart';

abstract class ClientPortalEvent {}

class LoadPortalMessages extends ClientPortalEvent {}
class RefreshPortalMessages extends ClientPortalEvent {}

class LoadPortalDocuments extends ClientPortalEvent {}
class RefreshPortalDocuments extends ClientPortalEvent {}

class MarkMessageAsRead extends ClientPortalEvent {
  final String messageId;
  MarkMessageAsRead(this.messageId);
}

class SearchPortalMessages extends ClientPortalEvent {
  final String query;
  SearchPortalMessages(this.query);
}

class SelectPortalMessage extends ClientPortalEvent {
  final PortalMessageModel message;
  SelectPortalMessage(this.message);
}

class SendPortalMessage extends ClientPortalEvent {
  final String subject;
  final String body;
  SendPortalMessage({required this.subject, required this.body});
}

class DownloadPortalDocument extends ClientPortalEvent {
  final String messageId;
  DownloadPortalDocument(this.messageId);
}

class UploadPortalDocument extends ClientPortalEvent {
  final String filePath;
  final String? title;
  UploadPortalDocument({required this.filePath, this.title});
}
