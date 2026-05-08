import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const keyAccessToken = 'accessToken';
  static const keyRefreshToken = 'refreshToken';
  static const keyTenantId = 'tenantId';
  static const keyUserSession = 'userSession';
  static const keyRememberMe = 'rememberMe';
  static const keySavedEmail = 'savedEmail';

  final _storage = const FlutterSecureStorage();

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> clear() => _storage.deleteAll();
}
