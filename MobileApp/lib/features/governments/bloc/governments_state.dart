import 'package:qadaya_lawyersys/features/governments/models/government.dart';

abstract class GovernmentsState {}

class GovernmentsInitial extends GovernmentsState {}

class GovernmentsLoading extends GovernmentsState {}

class GovernmentsLoaded extends GovernmentsState {
  GovernmentsLoaded(this.governments);
  final List<Government> governments;
}

class GovernmentsError extends GovernmentsState {
  GovernmentsError(this.message);
  final String message;
}

class GovernmentOperationSuccess extends GovernmentsState {
  GovernmentOperationSuccess(this.message);
  final String message;
}
