import '../models/admin_overview.dart';

abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final AdminOverview overview;
  AdminLoaded(this.overview);
}

class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}
