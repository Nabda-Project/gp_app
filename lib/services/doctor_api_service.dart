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

  /// Search for patients by name or phone number.
  ///
  /// Corresponds to `GET /api/doctor/search?doctorId=X&query=Y`.
  /// Returns patients NOT yet assigned to this doctor.
  static Future<List<PatientSearchModel>> searchPatients(
    int doctorId,
    String query,
  ) async {
    try {
      log(
        'Searching patients for doctor $doctorId with query "$query"',
        name: 'DoctorApiService',
      );
      final response = await DioClient.instance.get(
        ApiEndpoints.searchPatients,
        queryParameters: {
          'doctorId': doctorId,
          'query': query,
        },
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final results = data
          .map((item) => PatientSearchModel.fromJson(item as Map<String, dynamic>))
          .toList();

      log('Found ${results.length} patients', name: 'DoctorApiService');
      return results;
    } on DioException catch (e) {
      log('Search patients failed: ${e.message}', name: 'DoctorApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}
