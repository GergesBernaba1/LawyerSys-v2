import 'package:qadaya_lawyersys/features/contenders/models/contender.dart';

abstract class ContendersState {}

class ContendersInitial extends ContendersState {}
class ContendersLoading extends ContendersState {}

class ContendersLoaded extends ContendersState {
  ContendersLoaded(this.contenders);
  final List<ContenderModel> contenders;
}

class ContendersError extends ContendersState {
  ContendersError(this.message);
  final String message;
}

class ContenderDetailLoaded extends ContendersState {
  ContenderDetailLoaded(this.contender);
  final ContenderModel contender;
}

class ContenderOperationSuccess extends ContendersState {
  ContenderOperationSuccess(this.message);
  final String message;
}
