import 'package:dio/dio.dart';
import 'package:qadaya_lawyersys/core/api/api_constants.dart';
import 'package:qadaya_lawyersys/core/api/interceptors/auth_interceptor.dart';
import 'package:qadaya_lawyersys/core/api/interceptors/tenant_interceptor.dart';

class ApiClient {

  ApiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Version': '1.0',
          },
        ),) {
    _dio.interceptors.addAll([AuthInterceptor(), TenantInterceptor()]);
  }
  final Dio _dio;

  String _normalizePath(String path) {
    if (path.startsWith('/api/')) {
      return path.substring(4); // strip duplicate /api prefix (baseUrl already contains /api)
    }
    return path;
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(_normalizePath(path), queryParameters: queryParameters);
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) async {
    return _dio.post(_normalizePath(path), data: data);
  }

  Future<Response<dynamic>> put(String path, {dynamic data}) async {
    return _dio.put(_normalizePath(path), data: data);
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) async {
    return _dio.patch(_normalizePath(path), data: data);
  }

  Future<Response<dynamic>> delete(String path, {dynamic data}) async {
    return _dio.delete(_normalizePath(path), data: data);
  }
}
