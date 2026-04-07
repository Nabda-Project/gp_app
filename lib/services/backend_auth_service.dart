import 'dart:developer';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exceptions.dart';
import '../models/register_request.dart';
import '../models/login_request.dart';
import '../models/auth_response.dart';

/// Handles calls to back-end `/api/auth/*` endpoints.
class BackendAuthService {
  BackendAuthService._();

  /// Register a new user on the back-end.
  ///
  /// Returns the raw JSON map of the created `User` entity.
  /// Throws [ConflictException] if email already exists.
  static Future<Map<String, dynamic>> register(RegisterRequest request) async {
    try {
      log('Registering user on back-end: ${request.email}', name: 'BackendAuthService');
      final response = await DioClient.instance.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );
      log('Back-end registration successful', name: 'BackendAuthService');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log('Back-end registration failed: ${e.message}', name: 'BackendAuthService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Login and obtain a JWT token from the back-end.
  ///
  /// Returns an [AuthResponse] containing the JWT.
  /// Throws [UnauthorizedException] if credentials are invalid.
  static Future<AuthResponse> login(LoginRequest request) async {
    try {
      log('Logging in to back-end: ${request.email}', name: 'BackendAuthService');
      final response = await DioClient.instance.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      log('Back-end login successful, JWT obtained', name: 'BackendAuthService');
      return authResponse;
    } on DioException catch (e) {
      log('Back-end login failed: ${e.message}', name: 'BackendAuthService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Fetch the currently authenticated user's profile from the back-end.
  ///
  /// Requires a valid JWT to be stored (call after [login]).
  /// Returns the user data as a Map (includes `id`, `fullName`, `email`, `role`).
  static Future<Map<String, dynamic>> fetchCurrentUser() async {
    try {
      log('Fetching current user profile from back-end', name: 'BackendAuthService');
      final response = await DioClient.instance.get(ApiEndpoints.currentUser);
      log('Current user profile fetched successfully', name: 'BackendAuthService');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log('Failed to fetch current user: ${e.message}', name: 'BackendAuthService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}
