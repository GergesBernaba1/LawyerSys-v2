import '../models/esign_request.dart';

abstract class ESignState {}

class ESignInitial extends ESignState {}

class ESignLoading extends ESignState {}

class ESignLoaded extends ESignState {
  final List<ESignRequest> requests;

  ESignLoaded(this.requests);
}

class ESignError extends ESignState {
  final String message;

  ESignError(this.message);
}

class ESignOperationSuccess extends ESignState {
  final String message;

  ESignOperationSuccess(this.message);
}

class ESignShareLinkReady extends ESignState {
  final String url;

  ESignShareLinkReady(this.url);
}
