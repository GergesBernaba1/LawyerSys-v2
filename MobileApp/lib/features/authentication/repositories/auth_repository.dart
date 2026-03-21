import 'dart:convert';
import 'dart:io';

import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../../core/storage/secure_storage.dart';
import '../authentication/models/user_session.dart';
import '../authentication/models/login_request.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorage _secureStorage = SecureStorage();

  AuthRepository(this.apiClient);

  Future<UserSession> login(LoginRequest request) async {
    final response = await apiClient.post(ApiConstants.login, data: request.toJson());
    final responseData = Map<String, dynamic>.from(response.data as Map);
    final session = UserSession.fromJson(responseData);

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
        return await refreshToken(session.refreshToken);
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> forgotPassword(String email) async {
    await apiClient.post(ApiConstants.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword(String email, String password, String token) async {
    await apiClient.post(ApiConstants.resetPassword, data: {
      'email': email,
      'password': password,
      'token': token,
    });
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
    });
  }

  Future<void> unregisterDeviceToken(String deviceToken) async {
    await apiClient.post(ApiConstants.unregisterDeviceToken, data: {
      'token': deviceToken,
      'platform': Platform.operatingSystem,
    });
  }

  Future<void> _secureSession(UserSession session) async {
    await _secureStorage.write(SecureStorage.keyAccessToken, session.accessToken);
    await _secureStorage.write(SecureStorage.keyRefreshToken, session.refreshToken);
    await _secureStorage.write(SecureStorage.keyTenantId, session.tenantId);
    await _secureStorage.write(SecureStorage.keyUserSession, jsonEncode(session.toJson()));
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

