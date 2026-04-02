/// Base class for all API-related errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 401 – JWT expired or invalid.
class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Session expired. Please log in again.'])
      : super(message, statusCode: 401);
}

/// 403 – Insufficient permissions (e.g., patient calling doctor-only endpoint).
class ForbiddenException extends ApiException {
  ForbiddenException([String message = 'You do not have permission for this action.'])
      : super(message, statusCode: 403);
}

/// 400 / 422 – Validation errors from back-end.
class ValidationException extends ApiException {
  ValidationException([String message = 'Invalid data provided.'])
      : super(message, statusCode: 400);
}

/// 409 – Conflict (e.g., email already exists).
class ConflictException extends ApiException {
  ConflictException([String message = 'Resource already exists.'])
      : super(message, statusCode: 409);
}

/// 500 – Unexpected server error.
class ServerException extends ApiException {
  ServerException([String message = 'An unexpected server error occurred.'])
      : super(message, statusCode: 500);
}

/// No internet / DNS / timeout.
class NetworkException extends ApiException {
  NetworkException([String message = 'Network error. Please check your connection.'])
      : super(message);
}
