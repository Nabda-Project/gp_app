import 'dart:developer';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exceptions.dart';

/// Handles calls to back-end `/api/user/*` endpoints (non-auth).
class UserApiService {
  UserApiService._();

  /// Update the current user's profile.
  ///
  /// Only non-null fields in [data] will be updated on the server.
  /// Expects a Map with any of: fullName, phoneNumber, email, password,
  /// dateOfBirth (ISO string), gender, height, weight.
  ///
  /// Returns the updated user as a Map.
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      log('Updating profile on back-end', name: 'UserApiService');
      final response = await DioClient.instance.put(
        ApiEndpoints.updateProfile,
        data: data,
      );
      log('Profile updated successfully', name: 'UserApiService');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      log('Failed to update profile: ${e.message}', name: 'UserApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}
