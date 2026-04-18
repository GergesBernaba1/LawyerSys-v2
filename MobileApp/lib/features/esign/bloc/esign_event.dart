abstract class ESignEvent {}

class LoadESignRequests extends ESignEvent {
  final String? status;
  final String? search;

  LoadESignRequests({this.status, this.search});
}

class RefreshESignRequests extends ESignEvent {}

class CreateESignRequest extends ESignEvent {
  final String title;
  final String documentContent;
  final List<String> signerEmails;
  final DateTime? expiresAt;

  CreateESignRequest({
    required this.title,
    required this.documentContent,
    required this.signerEmails,
    this.expiresAt,
  });
}

class UpdateESignStatus extends ESignEvent {
  final String id;
  final String status;

  UpdateESignStatus(this.id, this.status);
}

class GetESignShareLink extends ESignEvent {
  final String id;

  GetESignShareLink(this.id);
}
