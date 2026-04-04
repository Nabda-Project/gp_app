import 'dart:developer';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../../services/token_service.dart';
import '../../services/backend_auth_service.dart';
import '../../models/login_request.dart';
import 'api_exceptions.dart';

/// Singleton Dio HTTP client with JWT interceptor and error mapping.
class DioClient {
  DioClient._();

  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(dio));
    dio.interceptors.add(_LoggingInterceptor());

    return dio;
  }

  /// Reset the Dio instance (useful after logout to clear any cached state).
  static void reset() {
    _dio?.close();
    _dio = null;
  }
}

/// Injects the JWT `Authorization: Bearer <token>` header on every request
/// (except auth endpoints which are public).
///
/// On 401 / 403 responses it automatically re-authenticates with the stored
/// credentials, saves the fresh JWT, and **retries the original request** so
/// the caller never sees the expired-token error.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;

  static const _publicPaths = ['/auth/login', '/auth/register'];

  /// Guard to prevent infinite re-login loops.
  bool _isRefreshing = false;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final isPublic = _publicPaths.any((path) => options.path.contains(path));

    if (!isPublic) {
      final token = await TokenService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final isAuthEndpoint =
        _publicPaths.any((p) => err.requestOptions.path.contains(p));

    // ── Auto-refresh on 401 / 403 (expired JWT) ──
    if ((statusCode == 401 || statusCode == 403) &&
        !isAuthEndpoint &&
        !_isRefreshing) {
      _isRefreshing = true;
      try {
        final credentials = await TokenService.getCredentials();
        if (credentials != null) {
          log('JWT expired – re-authenticating automatically …',
              name: 'DioClient');

          final authResponse = await BackendAuthService.login(
            LoginRequest(
              email: credentials['email']!,
              password: credentials['password']!,
            ),
          );

          // Persist the fresh token.
          await TokenService.saveToken(authResponse.token);

          // Clone the original request with the new token and retry.
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer ${authResponse.token}';

          log('Token refreshed – retrying ${opts.method} ${opts.path}',
              name: 'DioClient');

          final retryResponse = await _dio.fetch(opts);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        log('Auto-refresh failed: $e', name: 'DioClient');
      } finally {
        _isRefreshing = false;
      }
    }

    // ── Normal error mapping when refresh is not possible ──
    final apiException = _mapDioError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        message: apiException.message,
      ),
    );
  }

  static ApiException _mapDioError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return NetworkException('Connection timed out. Please try again.');
    }

    if (err.type == DioExceptionType.connectionError) {
      return NetworkException(
          'Cannot reach server. Please check your connection.');
    }

    final statusCode = err.response?.statusCode;
    final responseData = err.response?.data;
    String message = '';

    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] ?? responseData['error'] ?? '';
    } else if (responseData is String) {
      message = responseData;
    }

    switch (statusCode) {
      case 400:
        return ValidationException(
            message.isNotEmpty ? message : 'Invalid request.');
      case 401:
        return UnauthorizedException(message.isNotEmpty
            ? message
            : 'Session expired. Please log in again.');
      case 403:
        return ForbiddenException(
            message.isNotEmpty ? message : 'You do not have permission.');
      case 409:
        return ConflictException(
            message.isNotEmpty ? message : 'Resource already exists.');
      case 500:
        return ServerException(message.isNotEmpty
            ? message
            : 'Server error. Please try again later.');
      default:
        return ApiException(
          message.isNotEmpty ? message : 'Unexpected error (HTTP $statusCode).',
          statusCode: statusCode,
        );
    }
  }
}

/// Logs requests and responses for debugging.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log(
      '→ ${options.method} ${options.uri}',
      name: 'DioClient',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      name: 'DioClient',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log(
      '✖ ${err.response?.statusCode ?? 'NO_STATUS'} ${err.requestOptions.uri}: ${err.message}',
      name: 'DioClient',
      error: err,
    );
    handler.next(err);
  }
}
