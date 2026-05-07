import 'package:qadaya_lawyersys/features/esign/models/esign_request.dart';

abstract class ESignState {}

class ESignInitial extends ESignState {}

class ESignLoading extends ESignState {}

class ESignLoaded extends ESignState {

  ESignLoaded(this.requests);
  final List<ESignRequest> requests;
}

class ESignError extends ESignState {

  ESignError(this.message);
  final String message;
}

class ESignOperationSuccess extends ESignState {

  ESignOperationSuccess(this.message);
  final String message;
}

class ESignShareLinkReady extends ESignState {

  ESignShareLinkReady(this.url);
  final String url;
}
