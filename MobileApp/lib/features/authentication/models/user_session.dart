import 'package:qadaya_lawyersys/core/auth/roles.dart';

class UserSession {

  UserSession({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.tenantId,
    required this.tenantName,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiresAt,
    required this.roles,
    required this.permissions,
    required this.languageCode,
    required this.biometricEnabled,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    userId: (json['userId'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    fullName: (json['fullName'] as String?) ?? '',
    tenantId: (json['tenantId'] as String?) ?? '',
    tenantName: (json['tenantName'] as String?) ?? '',
    accessToken: (json['accessToken'] as String?) ?? '',
    refreshToken: (json['refreshToken'] as String?) ?? '',
    tokenExpiresAt: DateTime.tryParse(json['tokenExpiresAt']?.toString() ?? '') ?? DateTime.now(),
    roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    languageCode: (json['languageCode'] as String?) ?? 'en',
    biometricEnabled: (json['biometricEnabled'] as bool?) ?? false,
  );
  final String userId;
  final String email;
  final String fullName;
  final String tenantId;
  final String tenantName;
  final String accessToken;
  final String refreshToken;
  final DateTime tokenExpiresAt;
  final List<String> roles;
  final List<String> permissions;
  final String languageCode;
  final bool biometricEnabled;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    'fullName': fullName,
    'tenantId': tenantId,
    'tenantName': tenantName,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'tokenExpiresAt': tokenExpiresAt.toIso8601String(),
    'roles': roles,
    'permissions': permissions,
    'languageCode': languageCode,
    'biometricEnabled': biometricEnabled,
  };
}

extension UserSessionAuthorization on UserSession {
  // ── Role checks ─────────────────────────────────────────────────────────────

  bool hasRole(String role) =>
      roles.map((r) => r.toLowerCase()).contains(role.toLowerCase());

  bool isSuperAdmin() => hasRole(Roles.superAdmin);

  bool isAdmin() => hasRole(Roles.admin) || hasRole(Roles.superAdmin);

  bool isEmployee() =>
      hasRole(Roles.employee) &&
      !hasRole(Roles.admin) &&
      !hasRole(Roles.superAdmin);

  bool isCustomer() =>
      hasRole(Roles.customer) &&
      !hasRole(Roles.admin) &&
      !hasRole(Roles.employee) &&
      !hasRole(Roles.superAdmin);

  // ── Permission checks ───────────────────────────────────────────────────────

  bool hasPermission(String permission) {
    if (isAdmin()) return true;
    return permissions.map((p) => p.toLowerCase()).contains(permission.toLowerCase());
  }

  bool hasAnyPermission(List<String> required) {
    if (isAdmin()) return true;
    final normalized = required.map((p) => p.toLowerCase()).toSet();
    return permissions.map((p) => p.toLowerCase()).any(normalized.contains);
  }

  bool hasAllPermissions(List<String> required) {
    if (isAdmin()) return true;
    final normalized = permissions.map((p) => p.toLowerCase()).toSet();
    return required.every((p) => normalized.contains(p.toLowerCase()));
  }

  /// Returns true when the session can perform the given action.
  /// Admins bypass all permission checks.
  bool can(String permission) => hasPermission(permission);
}
