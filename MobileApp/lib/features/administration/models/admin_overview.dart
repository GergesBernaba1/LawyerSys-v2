class AdminOverview {
  final int totalUsers;
  final int totalCases;
  final int totalCustomers;
  final int totalEmployees;
  final int totalTenants;
  final int activeTenants;
  final Map<String, dynamic> extras;

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
      totalUsers: json['totalUsers'] ?? 0,
      totalCases: json['totalCases'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? 0,
      totalEmployees: json['totalEmployees'] ?? 0,
      totalTenants: json['totalTenants'] ?? 0,
      activeTenants: json['activeTenants'] ?? 0,
      extras: Map<String, dynamic>.from(json),
    );
  }
}
