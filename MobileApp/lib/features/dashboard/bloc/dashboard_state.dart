import 'package:qadaya_lawyersys/features/dashboard/models/dashboard_summary.dart';

abstract class DashboardState {}
class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  DashboardLoaded(this.summary);
  final DashboardSummary summary;
}
class DashboardError extends DashboardState {
  DashboardError(this.message);
  final String message;
}
class DashboardOffline extends DashboardState {}
