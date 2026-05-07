import 'package:dio/dio.dart';
import 'package:qadaya_lawyersys/core/storage/secure_storage.dart';

class TenantInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final tenantId = await _secureStorage.read(SecureStorage.keyTenantId);
      if (tenantId != null && tenantId.isNotEmpty) {
        options.headers['X-Tenant-Id'] = tenantId;
      }
    } catch (_) {
      // continue without tenant header; auth layer or backend should reject
    }

    super.onRequest(options, handler);
  }
}



