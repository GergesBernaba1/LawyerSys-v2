import '../../dashboard/models/dashboard_summary.dart';

abstract class DashboardEvent {}
class LoadDashboard extends DashboardEvent {}
class RefreshDashboard extends DashboardEvent {}
