import 'package:qadaya_lawyersys/features/sitings/models/siting_model.dart';

abstract class SitingsState {}

class SitingsInitial extends SitingsState {}

class SitingsLoading extends SitingsState {}

class SitingsLoaded extends SitingsState {
  SitingsLoaded(this.sitings);
  final List<SitingModel> sitings;
}

class SitingsError extends SitingsState {
  SitingsError(this.message);
  final String message;
}

class SitingOperationSuccess extends SitingsState {
  SitingOperationSuccess(this.message);
  final String message;
}
