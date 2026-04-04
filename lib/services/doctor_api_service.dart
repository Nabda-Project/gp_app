import 'dart:developer';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exceptions.dart';
import '../models/patient_response_model.dart';
import '../models/patient_search_model.dart';

/// Handles calls to back-end `/api/doctor/*` endpoints.
class DoctorApiService {
  DoctorApiService._();

  /// Assign a patient to a doctor.
  ///
  /// Corresponds to `POST /api/doctor/assign?doctorId=X&patientId=Y`.
  static Future<void> assignPatient(int doctorId, int patientId) async {
    try {
      log(
        'Assigning patient $patientId to doctor $doctorId',
        name: 'DoctorApiService',
      );
      await DioClient.instance.post(
        ApiEndpoints.assignPatient,
        queryParameters: {
          'doctorId': doctorId,
          'patientId': patientId,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      log('Patient assigned successfully', name: 'DoctorApiService');
    } on DioException catch (e) {
      log('Patient assignment failed: ${e.message}', name: 'DoctorApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Get all patients assigned to a doctor.
  ///
  /// Corresponds to `GET /api/doctor/patients/{doctorId}`.
  static Future<List<PatientResponseModel>> getAssignedPatients(int doctorId) async {
    try {
      log('Fetching patients for doctor $doctorId', name: 'DoctorApiService');
      final response = await DioClient.instance.get(
        ApiEndpoints.doctorPatients(doctorId),
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final patients = data
          .map((item) => PatientResponseModel.fromJson(item as Map<String, dynamic>))
          .toList();

      log('Fetched ${patients.length} patients', name: 'DoctorApiService');
      return patients;
    } on DioException catch (e) {
      log('Fetching patients failed: ${e.message}', name: 'DoctorApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Search for patients by name.
  ///
  /// Corresponds to `GET /api/doctor/search/name?doctorId=X&name=Y`.
  /// Returns patients NOT yet assigned to this doctor.
  static Future<List<PatientSearchModel>> searchByName(
    int doctorId,
    String name,
  ) async {
    try {
      log(
        'Searching patients by name for doctor $doctorId with name "$name"',
        name: 'DoctorApiService',
      );
      final response = await DioClient.instance.get(
        ApiEndpoints.searchByName,
        queryParameters: {
          'doctorId': doctorId,
          'name': name,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final results = data
          .map((item) => PatientSearchModel.fromJson(item as Map<String, dynamic>))
          .toList();

      log('Found ${results.length} patients by name', name: 'DoctorApiService');
      return results;
    } on DioException catch (e) {
      log('Search by name failed: ${e.message}', name: 'DoctorApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Search for patients by phone number.
  ///
  /// Corresponds to `GET /api/doctor/search/phone?doctorId=X&phone=Y`.
  /// Returns patients NOT yet assigned to this doctor.
  static Future<List<PatientSearchModel>> searchByPhone(
    int doctorId,
    String phone,
  ) async {
    try {
      log(
        'Searching patients by phone for doctor $doctorId with phone "$phone"',
        name: 'DoctorApiService',
      );
      final response = await DioClient.instance.get(
        ApiEndpoints.searchByPhone,
        queryParameters: {
          'doctorId': doctorId,
          'phone': phone,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final results = data
          .map((item) => PatientSearchModel.fromJson(item as Map<String, dynamic>))
          .toList();

      log('Found ${results.length} patients by phone', name: 'DoctorApiService');
      return results;
    } on DioException catch (e) {
      log('Search by phone failed: ${e.message}', name: 'DoctorApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Remove (unlink) a patient from a doctor.
  ///
  /// Corresponds to `DELETE /api/doctor/remove?doctorId=X&patientId=Y`.
  static Future<void> removePatient(int doctorId, int patientId) async {
    try {
      log(
        'Removing patient $patientId from doctor $doctorId',
        name: 'DoctorApiService',
      );
      await DioClient.instance.delete(
        ApiEndpoints.removePatient,
        queryParameters: {
          'doctorId': doctorId,
          'patientId': patientId,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      log('Patient removed successfully', name: 'DoctorApiService');
    } on DioException catch (e) {
      log('Patient removal failed: ${e.message}', name: 'DoctorApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}
