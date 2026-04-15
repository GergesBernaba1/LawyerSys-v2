import 'recent_activity.dart';

class DashboardSummary {
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
    totalCasesCount: json['totalCasesCount'] ?? 0,
    activeCasesCount: json['activeCasesCount'] ?? 0,
    upcomingHearingsCount: json['upcomingHearingsCount'] ?? 0,
    pendingTasksCount: json['pendingTasksCount'] ?? 0,
    customersCount: json['customersCount'] ?? 0,
    employeesCount: json['employeesCount'] ?? 0,
    filesCount: json['filesCount'] ?? 0,
    casesTrend: (json['casesTrend'] ?? 0).toDouble(),
    revenueThisMonth: (json['revenueThisMonth'] ?? 0).toDouble(),
    revenueTrend: (json['revenueTrend'] ?? 0).toDouble(),
    overdueTasks: json['overdueTasks'] ?? 0,
    activityHealthScore: (json['activityHealthScore'] ?? 0).toDouble(),
    completionScore: (json['completionScore'] ?? 0).toDouble(),
    attentionLevel: json['attentionLevel'] ?? 'On Track',
    recentActivities: (json['recentActivities'] as List<dynamic>?)?.map((e) => RecentActivity.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    recentCases: (json['recentCases'] as List<dynamic>?)?.map((e) => RecentCase.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    employeeMetrics: json['employeeMetrics'] != null ? EmployeeMetrics.fromJson(json['employeeMetrics']) : null,
  );

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
  final int assignedTasks;
  final int assignedLeads;
  final int assignedConsultations;
  final int overdueTasks;
  final int openCases;
  final int qualifiedLeads;
  final List<Task> overdueTaskList;
  final List<Lead> followUps;

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
    assignedTasks: json['assignedTasks'] ?? 0,
    assignedLeads: json['assignedLeads'] ?? 0,
    assignedConsultations: json['assignedConsultations'] ?? 0,
    overdueTasks: json['overdueTasks'] ?? 0,
    openCases: json['openCases'] ?? 0,
    qualifiedLeads: json['qualifiedLeads'] ?? 0,
    overdueTaskList: (json['overdueTaskList'] as List<dynamic>?)?.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    followUps: (json['followUps'] as List<dynamic>?)?.map((e) => Lead.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );

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
  final int caseId;
  final String caseName;
  final String caseNumber;
  final String caseType;
  final String status;

  RecentCase({
    required this.caseId,
    required this.caseName,
    required this.caseNumber,
    required this.caseType,
    required this.status,
  });

  factory RecentCase.fromJson(Map<String, dynamic> json) => RecentCase(
    caseId: json['caseId'] ?? 0,
    caseName: json['caseName'] ?? '',
    caseNumber: json['caseNumber'] ?? '',
    caseType: json['caseType'] ?? '',
    status: json['status'] ?? 'Active',
  );

  Map<String, dynamic> toJson() => {
    'caseId': caseId,
    'caseName': caseName,
    'caseNumber': caseNumber,
    'caseType': caseType,
    'status': status,
  };
}

class Task {
  final int id;
  final String taskName;
  final String? taskReminderDate;

  Task({
    required this.id,
    required this.taskName,
    this.taskReminderDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] ?? 0,
    taskName: json['taskName'] ?? json['task_Name'] ?? 'Task',
    taskReminderDate: json['taskReminderDate'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskName': taskName,
    'taskReminderDate': taskReminderDate,
  };
}

class Lead {
  final int id;
  final String fullName;
  final String? nextFollowUpAt;
  final String status;

  Lead({
    required this.id,
    required this.fullName,
    this.nextFollowUpAt,
    required this.status,
  });

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
    id: json['id'] ?? 0,
    fullName: json['fullName'] ?? 'Lead',
    nextFollowUpAt: json['nextFollowUpAt'],
    status: json['status'] ?? 'Pending',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'nextFollowUpAt': nextFollowUpAt,
    'status': status,
  };
}
