import '../models/contender.dart';

abstract class ContendersState {}

class ContendersInitial extends ContendersState {}
class ContendersLoading extends ContendersState {}

class ContendersLoaded extends ContendersState {
  final List<ContenderModel> contenders;
  ContendersLoaded(this.contenders);
}

class ContendersError extends ContendersState {
  final String message;
  ContendersError(this.message);
}

class ContenderDetailLoaded extends ContendersState {
  final ContenderModel contender;
  ContenderDetailLoaded(this.contender);
}

class ContenderOperationSuccess extends ContendersState {
  final String message;
  ContenderOperationSuccess(this.message);
}
