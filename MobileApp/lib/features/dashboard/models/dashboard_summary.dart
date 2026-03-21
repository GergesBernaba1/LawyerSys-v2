import 'recent_activity.dart';

class DashboardSummary {
  final int totalCasesCount;
  final int activeCasesCount;
  final int upcomingHearingsCount;
  final int pendingTasksCount;
  final List<RecentActivity> recentActivities;

  DashboardSummary({
    required this.totalCasesCount,
    required this.activeCasesCount,
    required this.upcomingHearingsCount,
    required this.pendingTasksCount,
    required this.recentActivities,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
    totalCasesCount: json['totalCasesCount'] ?? 0,
    activeCasesCount: json['activeCasesCount'] ?? 0,
    upcomingHearingsCount: json['upcomingHearingsCount'] ?? 0,
    pendingTasksCount: json['pendingTasksCount'] ?? 0,
    recentActivities: (json['recentActivities'] as List<dynamic>?)?.map((e) => RecentActivity.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'totalCasesCount': totalCasesCount,
    'activeCasesCount': activeCasesCount,
    'upcomingHearingsCount': upcomingHearingsCount,
    'pendingTasksCount': pendingTasksCount,
    'recentActivities': recentActivities.map((e) => e.toJson()).toList(),
  };
}
