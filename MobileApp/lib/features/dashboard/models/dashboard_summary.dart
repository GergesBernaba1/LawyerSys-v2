import 'package:qadaya_lawyersys/features/dashboard/models/recent_activity.dart';

class DashboardSummary {

  DashboardSummary({
    required this.totalCasesCount,
    required this.activeCasesCount,
    required this.upcomingHearingsCount,
    required this.pendingTasksCount,
    required this.customersCount,
    required this.employeesCount,
    required this.filesCount,
    required this.casesTrend,
    required this.revenueThisMonth,
    required this.revenueTrend,
    required this.overdueTasks,
    required this.activityHealthScore,
    required this.completionScore,
    required this.attentionLevel,
    required this.recentActivities,
    required this.recentCases,
    this.employeeMetrics,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
    totalCasesCount: (json['totalCasesCount'] as int?) ?? 0,
    activeCasesCount: (json['activeCasesCount'] as int?) ?? 0,
    upcomingHearingsCount: (json['upcomingHearingsCount'] as int?) ?? 0,
    pendingTasksCount: (json['pendingTasksCount'] as int?) ?? 0,
    customersCount: (json['customersCount'] as int?) ?? 0,
    employeesCount: (json['employeesCount'] as int?) ?? 0,
    filesCount: (json['filesCount'] as int?) ?? 0,
    casesTrend: (json['casesTrend'] as num? ?? 0).toDouble(),
    revenueThisMonth: (json['revenueThisMonth'] as num? ?? 0).toDouble(),
    revenueTrend: (json['revenueTrend'] as num? ?? 0).toDouble(),
    overdueTasks: (json['overdueTasks'] as int?) ?? 0,
    activityHealthScore: (json['activityHealthScore'] as num? ?? 0).toDouble(),
    completionScore: (json['completionScore'] as num? ?? 0).toDouble(),
    attentionLevel: (json['attentionLevel'] as String?) ?? 'On Track',
    recentActivities: (json['recentActivities'] as List<dynamic>?)?.map((e) => RecentActivity.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    recentCases: (json['recentCases'] as List<dynamic>?)?.map((e) => RecentCase.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    employeeMetrics: json['employeeMetrics'] != null ? EmployeeMetrics.fromJson(json['employeeMetrics'] as Map<String, dynamic>) : null,
  );
  final int totalCasesCount;
  final int activeCasesCount;
  final int upcomingHearingsCount;
  final int pendingTasksCount;
  final int customersCount;
  final int employeesCount;
  final int filesCount;
  final double casesTrend;
  final double revenueThisMonth;
  final double revenueTrend;
  final int overdueTasks;
  final double activityHealthScore;
  final double completionScore;
  final String attentionLevel;
  final List<RecentActivity> recentActivities;
  final List<RecentCase> recentCases;
  final EmployeeMetrics? employeeMetrics;

  Map<String, dynamic> toJson() => {
    'totalCasesCount': totalCasesCount,
    'activeCasesCount': activeCasesCount,
    'upcomingHearingsCount': upcomingHearingsCount,
    'pendingTasksCount': pendingTasksCount,
    'customersCount': customersCount,
    'employeesCount': employeesCount,
    'filesCount': filesCount,
    'casesTrend': casesTrend,
    'revenueThisMonth': revenueThisMonth,
    'revenueTrend': revenueTrend,
    'overdueTasks': overdueTasks,
    'activityHealthScore': activityHealthScore,
    'completionScore': completionScore,
    'attentionLevel': attentionLevel,
    'recentActivities': recentActivities.map((e) => e.toJson()).toList(),
    'recentCases': recentCases.map((e) => e.toJson()).toList(),
    'employeeMetrics': employeeMetrics?.toJson(),
  };
}

class EmployeeMetrics {

  EmployeeMetrics({
    required this.assignedTasks,
    required this.assignedLeads,
    required this.assignedConsultations,
    required this.overdueTasks,
    required this.openCases,
    required this.qualifiedLeads,
    required this.overdueTaskList,
    required this.followUps,
  });

  factory EmployeeMetrics.fromJson(Map<String, dynamic> json) => EmployeeMetrics(
    assignedTasks: (json['assignedTasks'] as int?) ?? 0,
    assignedLeads: (json['assignedLeads'] as int?) ?? 0,
    assignedConsultations: (json['assignedConsultations'] as int?) ?? 0,
    overdueTasks: (json['overdueTasks'] as int?) ?? 0,
    openCases: (json['openCases'] as int?) ?? 0,
    qualifiedLeads: (json['qualifiedLeads'] as int?) ?? 0,
    overdueTaskList: (json['overdueTaskList'] as List<dynamic>?)?.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    followUps: (json['followUps'] as List<dynamic>?)?.map((e) => Lead.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
  final int assignedTasks;
  final int assignedLeads;
  final int assignedConsultations;
  final int overdueTasks;
  final int openCases;
  final int qualifiedLeads;
  final List<Task> overdueTaskList;
  final List<Lead> followUps;

  Map<String, dynamic> toJson() => {
    'assignedTasks': assignedTasks,
    'assignedLeads': assignedLeads,
    'assignedConsultations': assignedConsultations,
    'overdueTasks': overdueTasks,
    'openCases': openCases,
    'qualifiedLeads': qualifiedLeads,
    'overdueTaskList': overdueTaskList.map((e) => e.toJson()).toList(),
    'followUps': followUps.map((e) => e.toJson()).toList(),
  };
}

class RecentCase {

  RecentCase({
    required this.caseId,
    required this.caseName,
    required this.caseNumber,
    required this.caseType,
    required this.status,
  });

  factory RecentCase.fromJson(Map<String, dynamic> json) => RecentCase(
    caseId: (json['caseId'] as int?) ?? 0,
    caseName: (json['caseName'] as String?) ?? '',
    caseNumber: (json['caseNumber'] as String?) ?? '',
    caseType: (json['caseType'] as String?) ?? '',
    status: (json['status'] as String?) ?? 'Active',
  );
  final int caseId;
  final String caseName;
  final String caseNumber;
  final String caseType;
  final String status;

  Map<String, dynamic> toJson() => {
    'caseId': caseId,
    'caseName': caseName,
    'caseNumber': caseNumber,
    'caseType': caseType,
    'status': status,
  };
}

class Task {

  Task({
    required this.id,
    required this.taskName,
    this.taskReminderDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: (json['id'] as int?) ?? 0,
    taskName: (json['taskName'] as String?) ?? (json['task_Name'] as String?) ?? 'Task',
    taskReminderDate: json['taskReminderDate'] as String?,
  );
  final int id;
  final String taskName;
  final String? taskReminderDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskName': taskName,
    'taskReminderDate': taskReminderDate,
  };
}

class Lead {

  Lead({
    required this.id,
    required this.fullName,
    this.nextFollowUpAt,
    required this.status,
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
    id: (json['id'] as int?) ?? 0,
    fullName: (json['fullName'] as String?) ?? 'Lead',
    nextFollowUpAt: json['nextFollowUpAt'] as String?,
    status: (json['status'] as String?) ?? 'Pending',
  );
  final int id;
  final String fullName;
  final String? nextFollowUpAt;
  final String status;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'nextFollowUpAt': nextFollowUpAt,
    'status': status,
  };
}
