import '../models/dashboard_summary.dart';

abstract class DashboardState {}
class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;
  DashboardLoaded(this.summary);
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
class DashboardOffline extends DashboardState {}
