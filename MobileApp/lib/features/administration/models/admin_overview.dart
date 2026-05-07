class AdminOverview {

  AdminOverview({
    required this.totalUsers,
    required this.totalCases,
    required this.totalCustomers,
    required this.totalEmployees,
    required this.totalTenants,
    required this.activeTenants,
    required this.extras,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    return AdminOverview(
      totalUsers: (json['totalUsers'] as int?) ?? 0,
      totalCases: (json['totalCases'] as int?) ?? 0,
      totalCustomers: (json['totalCustomers'] as int?) ?? 0,
      totalEmployees: (json['totalEmployees'] as int?) ?? 0,
      totalTenants: (json['totalTenants'] as int?) ?? 0,
      activeTenants: (json['activeTenants'] as int?) ?? 0,
      extras: Map<String, dynamic>.from(json),
    );
  }
  final int totalUsers;
  final int totalCases;
  final int totalCustomers;
  final int totalEmployees;
  final int totalTenants;
  final int activeTenants;
  final Map<String, dynamic> extras;
}
