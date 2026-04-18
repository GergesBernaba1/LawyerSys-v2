import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/tenant_interceptor.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Version': '1.0',
          },
        )) {
    _dio.interceptors.addAll([AuthInterceptor(), TenantInterceptor()]);
  }

  String _normalizePath(String path) {
    if (path.startsWith('/api/')) {
      return path.substring(4); // strip duplicate /api prefix (baseUrl already contains /api)
    }
    return path;
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(_normalizePath(path), queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) async {
    return await _dio.post(_normalizePath(path), data: data);
  }

  Future<Response<dynamic>> put(String path, {dynamic data}) async {
    return await _dio.put(_normalizePath(path), data: data);
  }

  Future<Response<dynamic>> delete(String path, {dynamic data}) async {
    return await _dio.delete(_normalizePath(path), data: data);
  }
}
