import 'package:flutter_test/flutter_test.dart';
import 'package:qadaya_lawyersys/core/error/failures.dart';
import 'package:dio/dio.dart';

void main() {
  group('ErrorHandler', () {
    test('handleDioError converts connection timeout to NetworkFailure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final failure = ErrorHandler.handleDioError(error);

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('timeout'));
    });

    test('handleDioError converts 401 response to AuthFailure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );

      final failure = ErrorHandler.handleDioError(error);

      expect(failure, isA<AuthFailure>());
      expect(failure.code, equals(401));
    });

    test('handleDioError converts 404 response to NotFoundFailure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );

      final failure = ErrorHandler.handleDioError(error);

      expect(failure, isA<NotFoundFailure>());
      expect(failure.code, equals(404));
    });

    test('handleDioError converts 500 response to ServerFailure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );

      final failure = ErrorHandler.handleDioError(error);

      expect(failure, isA<ServerFailure>());
      expect(failure.code, equals(500));
    });

    test('handleDioError extracts field errors from validation response', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {
            'message': 'Validation failed',
            'errors': {
              'email': ['Email is required', 'Email must be valid'],
              'password': ['Password is too short'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final failure = ErrorHandler.handleDioError(error) as ValidationFailure;

      expect(failure, isA<ValidationFailure>());
      expect(failure.fieldErrors, isNotNull);
      expect(failure.fieldErrors!['email'], equals('Email is required'));
      expect(failure.fieldErrors!['password'], equals('Password is too short'));
    });

    test('isNetworkError identifies NetworkFailure correctly', () {
      const networkFailure = NetworkFailure(message: 'No connection');
      const authFailure = AuthFailure(message: 'Unauthorized');

      expect(ErrorHandler.isNetworkError(networkFailure), isTrue);
      expect(ErrorHandler.isNetworkError(authFailure), isFalse);
    });

    test('isAuthError identifies auth-related failures', () {
      const authFailure = AuthFailure(message: 'Unauthorized');
      const unauthorizedFailure = UnauthorizedFailure(message: 'Forbidden');
      const networkFailure = NetworkFailure(message: 'No connection');

      expect(ErrorHandler.isAuthError(authFailure), isTrue);
      expect(ErrorHandler.isAuthError(unauthorizedFailure), isTrue);
      expect(ErrorHandler.isAuthError(networkFailure), isFalse);
    });
  });

  group('Failure Extensions', () {
    test('isNetworkError extension works correctly', () {
      const networkFailure = NetworkFailure(message: 'No connection');
      const authFailure = AuthFailure(message: 'Unauthorized');

      expect(networkFailure.isNetworkError, isTrue);
      expect(authFailure.isNetworkError, isFalse);
    });

    test('userMessage extension returns the message', () {
      const failure = NetworkFailure(message: 'Connection timeout');

      expect(failure.userMessage, equals('Connection timeout'));
    });
  });

  group('ValidationFailure', () {
    test('includes field errors in equality comparison', () {
      const failure1 = ValidationFailure(
        message: 'Validation failed',
        fieldErrors: {'email': 'Required'},
      );
      const failure2 = ValidationFailure(
        message: 'Validation failed',
        fieldErrors: {'email': 'Required'},
      );
      const failure3 = ValidationFailure(
        message: 'Validation failed',
        fieldErrors: {'email': 'Invalid'},
      );

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
    });
  });
}
