import 'package:qadaya_lawyersys/features/client-portal/models/portal_message.dart';

abstract class ClientPortalEvent {}

class LoadPortalMessages extends ClientPortalEvent {}
class RefreshPortalMessages extends ClientPortalEvent {}

class LoadPortalDocuments extends ClientPortalEvent {}
class RefreshPortalDocuments extends ClientPortalEvent {}

class MarkMessageAsRead extends ClientPortalEvent {
  MarkMessageAsRead(this.messageId);
  final String messageId;
}

class SearchPortalMessages extends ClientPortalEvent {
  SearchPortalMessages(this.query);
  final String query;
}

class SelectPortalMessage extends ClientPortalEvent {
  SelectPortalMessage(this.message);
  final PortalMessageModel message;
}

class SendPortalMessage extends ClientPortalEvent {
  SendPortalMessage({required this.subject, required this.body});
  final String subject;
  final String body;
}

class DownloadPortalDocument extends ClientPortalEvent {
  DownloadPortalDocument(this.messageId);
  final String messageId;
}

class UploadPortalDocument extends ClientPortalEvent {
  UploadPortalDocument({required this.filePath, this.title});
  final String filePath;
  final String? title;
}

class LoadPortalOverview extends ClientPortalEvent {}
