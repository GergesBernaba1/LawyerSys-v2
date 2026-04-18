import 'package:dio/dio.dart';

import '../../api/api_constants.dart';
import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final requestPath = err.requestOptions.path;

    if ((statusCode == 401 || statusCode == 403) &&
        !requestPath.contains(ApiConstants.refreshToken) &&
        !requestPath.contains(ApiConstants.login)) {
      try {
        final refreshToken = await _secureStorage.read(SecureStorage.keyRefreshToken);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshDio = Dio(BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ));

          final refreshResponse = await refreshDio.post(ApiConstants.refreshToken, data: {'refreshToken': refreshToken});

          if (refreshResponse.statusCode == 200 && refreshResponse.data != null) {
            final data = refreshResponse.data as Map<String, dynamic>;
            final newAccessToken = data['accessToken'] as String?;
            final newRefreshToken = data['refreshToken'] as String?;

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              await _secureStorage.write(SecureStorage.keyAccessToken, newAccessToken);
              if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
                await _secureStorage.write(SecureStorage.keyRefreshToken, newRefreshToken);
              }

              final retryDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
              final retryRequest = err.requestOptions;
              retryRequest.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryResponse = await retryDio.fetch(retryRequest);
              handler.resolve(retryResponse);
              return;
            }
          }
        }
      } catch (_) {
        // If refresh fails, fall through to error handler.
      }
    }

    super.onError(err, handler);
  }
}


