import 'package:qadaya_lawyersys/features/administration/models/admin_overview.dart';

abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  AdminLoaded(this.overview);
  final AdminOverview overview;
}

class AdminError extends AdminState {
  AdminError(this.message);
  final String message;
}
