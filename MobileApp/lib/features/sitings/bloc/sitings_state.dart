import '../models/siting_model.dart';

abstract class SitingsState {}

class SitingsInitial extends SitingsState {}

class SitingsLoading extends SitingsState {}

class SitingsLoaded extends SitingsState {
  final List<SitingModel> sitings;
  SitingsLoaded(this.sitings);
}

class SitingsError extends SitingsState {
  final String message;
  SitingsError(this.message);
}

class SitingOperationSuccess extends SitingsState {
  final String message;
  SitingOperationSuccess(this.message);
}
