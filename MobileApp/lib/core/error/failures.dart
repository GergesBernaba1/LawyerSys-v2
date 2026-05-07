import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Base class for all app failures
abstract class Failure extends Equatable {
  final String message;
  final int? code;
  final dynamic originalError;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code,
    super.originalError,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Unauthorized access failures
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Cache/local storage failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Helper class to handle errors and convert them to failures
class ErrorHandler {
  /// Convert a Dio error to a Failure
  static Failure handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          message: 'Connection timeout. Please check your internet connection.',
          code: error.response?.statusCode,
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkFailure(
          message: 'No internet connection. Please check your connection and try again.',
          code: error.response?.statusCode,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);

      case DioExceptionType.cancel:
        return const NetworkFailure(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.badCertificate:
        return NetworkFailure(
          message: 'Certificate validation failed.',
          originalError: error,
        );

      case DioExceptionType.unknown:
      default:
        return UnknownFailure(
          message: 'An unexpected error occurred. Please try again.',
          originalError: error,
        );
    }
  }

  /// Handle HTTP response errors
  static Failure _handleResponseError(Response? response) {
    if (response == null) {
      return const UnknownFailure(
        message: 'An unexpected error occurred.',
      );
    }

    final statusCode = response.statusCode;
    final data = response.data;

    // Extract error message from response
    String message = 'An error occurred.';
    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? data['title'] ?? message;
    }

    switch (statusCode) {
      case 400:
        // Check if it's a validation error
        if (data is Map<String, dynamic> && data.containsKey('errors')) {
          return ValidationFailure(
            message: message,
            code: statusCode,
            originalError: response,
            fieldErrors: _extractFieldErrors(data['errors']),
          );
        }
        return ValidationFailure(
          message: message,
          code: statusCode,
          originalError: response,
        );

      case 401:
        return AuthFailure(
          message: 'Session expired. Please log in again.',
          code: statusCode,
          originalError: response,
        );

      case 403:
        return UnauthorizedFailure(
          message: 'You do not have permission to perform this action.',
          code: statusCode,
          originalError: response,
        );

      case 404:
        return NotFoundFailure(
          message: 'The requested resource was not found.',
          code: statusCode,
          originalError: response,
        );

      case 422:
        if (data is Map<String, dynamic> && data.containsKey('errors')) {
          return ValidationFailure(
            message: message,
            code: statusCode,
            originalError: response,
            fieldErrors: _extractFieldErrors(data['errors']),
          );
        }
        return ValidationFailure(
          message: message,
          code: statusCode,
          originalError: response,
        );

      case 500:
      case 502:
      case 503:
        return ServerFailure(
          message: 'Server error. Please try again later.',
          code: statusCode,
          originalError: response,
        );

      default:
        return UnknownFailure(
          message: message,
          code: statusCode,
          originalError: response,
        );
    }
  }

  /// Extract field-specific errors from validation response
  static Map<String, String>? _extractFieldErrors(dynamic errors) {
    if (errors is Map<String, dynamic>) {
      final fieldErrors = <String, String>{};
      errors.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          fieldErrors[key] = value.first.toString();
        } else if (value is String) {
          fieldErrors[key] = value;
        }
      });
      return fieldErrors.isNotEmpty ? fieldErrors : null;
    }
    return null;
  }

  /// Convert any error to a Failure
  static Failure handleError(dynamic error) {
    if (error is DioException) {
      return handleDioError(error);
    } else if (error is Failure) {
      return error;
    } else {
      return UnknownFailure(
        message: error.toString(),
        originalError: error,
      );
    }
  }

  /// Get user-friendly error message from a failure
  static String getErrorMessage(Failure failure) {
    return failure.message;
  }

  /// Check if the error is network-related
  static bool isNetworkError(Failure failure) {
    return failure is NetworkFailure;
  }

  /// Check if the error is authentication-related
  static bool isAuthError(Failure failure) {
    return failure is AuthFailure || failure is UnauthorizedFailure;
  }

  /// Check if the error is a validation error
  static bool isValidationError(Failure failure) {
    return failure is ValidationFailure;
  }
}

/// Extension on Failure for easier error handling
extension FailureExtension on Failure {
  bool get isNetworkError => ErrorHandler.isNetworkError(this);
  bool get isAuthError => ErrorHandler.isAuthError(this);
  bool get isValidationError => ErrorHandler.isValidationError(this);
  
  String get userMessage => ErrorHandler.getErrorMessage(this);
}
