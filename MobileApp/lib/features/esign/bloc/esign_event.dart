abstract class ESignEvent {}

class LoadESignRequests extends ESignEvent {

  LoadESignRequests({this.status, this.search});
  final String? status;
  final String? search;
}

class RefreshESignRequests extends ESignEvent {}

class CreateESignRequest extends ESignEvent {

  CreateESignRequest({
    required this.title,
    required this.documentContent,
    required this.signerEmails,
    this.expiresAt,
  });
  final String title;
  final String documentContent;
  final List<String> signerEmails;
  final DateTime? expiresAt;
}

class UpdateESignStatus extends ESignEvent {

  UpdateESignStatus(this.id, this.status);
  final String id;
  final String status;
}

class GetESignShareLink extends ESignEvent {

  GetESignShareLink(this.id);
  final String id;
}
