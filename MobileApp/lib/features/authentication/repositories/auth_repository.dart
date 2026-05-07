import 'dart:convert';
import 'dart:io';

import 'package:qadaya_lawyersys/core/api/api_client.dart';
import 'package:qadaya_lawyersys/core/api/api_constants.dart';
import 'package:qadaya_lawyersys/core/storage/secure_storage.dart';
import 'package:qadaya_lawyersys/features/authentication/models/login_request.dart';
import 'package:qadaya_lawyersys/features/authentication/models/user_session.dart';

class AuthRepository {

  AuthRepository(this.apiClient);
  final ApiClient apiClient;
  final SecureStorage _secureStorage = SecureStorage();

  Future<UserSession> login(LoginRequest request) async {
    final response = await apiClient.post(ApiConstants.login, data: request.toJson());
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final session = _mapLoginResponseToSession(responseData, request.userName);

    await _secureSession(session);

    return session;
  }

  Future<UserSession> register(Map<String, dynamic> registrationData) async {
    final response = await apiClient.post(ApiConstants.register, data: registrationData);
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final session = UserSession.fromJson(responseData);

    await _secureSession(session);

    return session;
  }

  Future<UserSession?> getStoredSession() async {
    final raw = await _secureStorage.read(SecureStorage.keyUserSession);
    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final session = UserSession.fromJson(data);
      if (session.tokenExpiresAt.isBefore(DateTime.now())) {
        if (session.refreshToken.isEmpty) return null;
        return await refreshToken(session.refreshToken);
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> forgotPassword(String email) async {
    await apiClient.post(ApiConstants.forgotPassword, data: {'userName': email});
  }

  Future<void> resetPassword(String email, String password, String token) async {
    await apiClient.post(ApiConstants.resetPassword, data: {
      'userName': email,
      'newPassword': password,
      'token': token,
    },);
  }

  Future<void> logout() async {
    await apiClient.post(ApiConstants.logout);
    await _secureStorage.clear();
  }

  Future<UserSession?> refreshToken(String refreshToken) async {
    final response = await apiClient.post(ApiConstants.refreshToken, data: {'refreshToken': refreshToken});
    if (response.statusCode == 200 && response.data != null) {
      final session = UserSession.fromJson(Map<String, dynamic>.from(response.data as Map));
      await _secureSession(session);
      return session;
    }
    return null;
  }

  Future<void> registerDeviceToken(String deviceToken, {String? platform}) async {
    await apiClient.post(ApiConstants.registerDeviceToken, data: {
      'token': deviceToken,
      'platform': platform ?? Platform.operatingSystem,
    },);
  }

  Future<void> unregisterDeviceToken(String deviceToken) async {
    await apiClient.post(ApiConstants.unregisterDeviceToken, data: {
      'token': deviceToken,
      'platform': Platform.operatingSystem,
    },);
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await apiClient.get('/account/me');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<Map<String, dynamic>>> getCountries() async {
    final response = await apiClient.get('/account/countries');
    final raw = response.data;
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList();
  }

  Future<Map<String, dynamic>> updateMyProfile({
    required String userName,
    required String fullName,
    required String email,
    required int countryId,
    String? phoneNumber,
    String? address,
    String? jobTitle,
    String? tenantName,
    String? tenantPhoneNumber,
  }) async {
    final response = await apiClient.put('/account/me', data: {
      'userName': userName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber ?? '',
      'countryId': countryId,
      'address': address ?? '',
      'jobTitle': jobTitle ?? '',
      'tenantName': tenantName ?? '',
      'tenantPhoneNumber': tenantPhoneNumber ?? '',
    },);

    final data = Map<String, dynamic>.from(response.data as Map);
    await updateStoredSession(
      accessToken: data['token']?.toString(),
      fullName: fullName,
      email: email,
    );
    return data;
  }

  Future<void> updateStoredSession({
    String? accessToken,
    String? fullName,
    String? email,
  }) async {
    if (accessToken != null && accessToken.isNotEmpty) {
      await _secureStorage.write(SecureStorage.keyAccessToken, accessToken);
    }

    final raw = await _secureStorage.read(SecureStorage.keyUserSession);
    if (raw == null || raw.isEmpty) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final current = UserSession.fromJson(data);
      final updated = UserSession(
        userId: current.userId,
        email: email ?? current.email,
        fullName: fullName ?? current.fullName,
        tenantId: current.tenantId,
        tenantName: current.tenantName,
        accessToken: (accessToken != null && accessToken.isNotEmpty)
            ? accessToken
            : current.accessToken,
        refreshToken: current.refreshToken,
        tokenExpiresAt: current.tokenExpiresAt,
        roles: current.roles,
        permissions: current.permissions,
        languageCode: current.languageCode,
        biometricEnabled: current.biometricEnabled,
      );
      await _secureStorage.write(
          SecureStorage.keyUserSession, jsonEncode(updated.toJson()),);
    } catch (_) {
      // keep old session if parsing fails
    }
  }

  Future<void> _secureSession(UserSession session) async {
    await _secureStorage.write(SecureStorage.keyAccessToken, session.accessToken);
    await _secureStorage.write(SecureStorage.keyRefreshToken, session.refreshToken);
    await _secureStorage.write(SecureStorage.keyTenantId, session.tenantId);
    await _secureStorage.write(SecureStorage.keyUserSession, jsonEncode(session.toJson()));
  }

  UserSession _mapLoginResponseToSession(
      Map<String, dynamic> responseData, String fallbackUserNameOrEmail,) {
    final token = (responseData['token'] ?? responseData['accessToken'] ?? '').toString();
    if (token.isEmpty) {
      throw const FormatException('Login response does not include an access token.');
    }

    final claims = _decodeJwt(token);
    final expiresFromResponse = responseData['expires']?.toString();
    final expiresFromJwt = _extractJwtExpiry(claims);
    final tokenExpiry = expiresFromResponse != null
        ? DateTime.tryParse(expiresFromResponse)?.toUtc()
        : null;

    final roles = _extractRoles(claims);

    return UserSession(
      userId: (claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
              claims['nameid'] ??
              claims['sub'] ??
              '')
          .toString(),
      email: (claims['email'] ?? fallbackUserNameOrEmail).toString(),
      fullName: (claims['fullName'] ?? '').toString(),
      tenantId: (claims['tenant_id'] ?? claims['firm_id'] ?? '').toString(),
      tenantName: (claims['tenant_name'] ?? '').toString(),
      accessToken: token,
      refreshToken: (responseData['refreshToken'] ?? '').toString(),
      tokenExpiresAt:
          tokenExpiry ?? expiresFromJwt ?? DateTime.now().toUtc().add(const Duration(hours: 1)),
      roles: roles,
      permissions: const [],
      languageCode: 'en',
      biometricEnabled: false,
    );
  }

  Map<String, dynamic> _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return const {};
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      return Map<String, dynamic>.from(jsonDecode(payload) as Map);
    } catch (_) {
      return const {};
    }
  }

  DateTime? _extractJwtExpiry(Map<String, dynamic> claims) {
    final rawExp = claims['exp'];
    if (rawExp is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawExp * 1000, isUtc: true);
    }

    if (rawExp is String) {
      final parsedSeconds = int.tryParse(rawExp);
      if (parsedSeconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsedSeconds * 1000, isUtc: true);
      }
    }

    return null;
  }

  List<String> _extractRoles(Map<String, dynamic> claims) {
    final roleClaim = claims['role'] ??
        claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];

    if (roleClaim is List) {
      return roleClaim.map((role) => role.toString()).toList();
    }

    if (roleClaim is String && roleClaim.isNotEmpty) {
      return [roleClaim];
    }

    return const [];
  }

  Future<bool> setBiometricEnabled(bool enabled) async {
    final stored = await getStoredSession();
    if (stored == null) return false;

    final updated = UserSession(
      userId: stored.userId,
      email: stored.email,
      fullName: stored.fullName,
      tenantId: stored.tenantId,
      tenantName: stored.tenantName,
      accessToken: stored.accessToken,
      refreshToken: stored.refreshToken,
      tokenExpiresAt: stored.tokenExpiresAt,
      roles: stored.roles,
      permissions: stored.permissions,
      languageCode: stored.languageCode,
      biometricEnabled: enabled,
    );

    await _secureSession(updated);
    return true;
  }
}


