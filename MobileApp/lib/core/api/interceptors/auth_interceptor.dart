import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:qadaya_lawyersys/core/api/api_constants.dart';
import 'package:qadaya_lawyersys/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  // Serialises concurrent refresh attempts: all waiters join the same Future.
  static Future<String?>? _refreshFuture;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _secureStorage.read(SecureStorage.keyAccessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // ignore storage failures and continue (will likely receive 401)
    }

    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

    if ((statusCode == 401 || statusCode == 403) &&
        !requestPath.contains(ApiConstants.refreshToken) &&
        !requestPath.contains(ApiConstants.login)) {
      try {
        final newToken = await _refreshAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';

          final retryDio = Dio(BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),);
          final retryResponse = await retryDio.fetch<dynamic>(retryOptions);
          handler.resolve(retryResponse);
          return;
        }
      } catch (e) {
        debugPrint('AuthInterceptor: token refresh failed: $e');
        // Clear stored credentials so the app can redirect to login.
        await _secureStorage.clear();
      }
    }

    super.onError(err, handler);
  }

  /// Returns the new access token, or null if refresh is unavailable.
  /// Concurrent callers share a single in-flight refresh request.
  Future<String?> _refreshAccessToken() async {
    if (_refreshFuture != null) {
      return _refreshFuture;
    }

    _refreshFuture = _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });

    return _refreshFuture;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _secureStorage.read(SecureStorage.keyRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final refreshDio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),);

    final response = await refreshDio.post<Map<String, dynamic>>(
      ApiConstants.refreshToken,
      data: {'refreshToken': refreshToken},
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        await _secureStorage.write(SecureStorage.keyAccessToken, newAccessToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _secureStorage.write(SecureStorage.keyRefreshToken, newRefreshToken);
        }
        return newAccessToken;
      }
    }

    return null;
  }
}
