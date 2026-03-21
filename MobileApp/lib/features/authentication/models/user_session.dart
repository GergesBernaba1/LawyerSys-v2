class UserSession {
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
    userId: json['userId'] ?? '',
    email: json['email'] ?? '',
    fullName: json['fullName'] ?? '',
    tenantId: json['tenantId'] ?? '',
    tenantName: json['tenantName'] ?? '',
    accessToken: json['accessToken'] ?? '',
    refreshToken: json['refreshToken'] ?? '',
    tokenExpiresAt: DateTime.parse(json['tokenExpiresAt'] ?? DateTime.now().toIso8601String()),
    roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    languageCode: json['languageCode'] ?? 'en',
    biometricEnabled: json['biometricEnabled'] ?? false,
  );

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
