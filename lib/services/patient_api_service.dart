import 'dart:developer';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exceptions.dart';
import '../models/doctor_info_model.dart';

/// Handles calls to back-end `/api/patient/*` endpoints.
class PatientApiService {
  PatientApiService._();

  /// Get the doctor assigned to a patient.
  ///
  /// Returns [DoctorInfoModel] if a doctor is assigned, or `null` if none
  /// (backend returns 204 No Content).
  ///
  /// Corresponds to `GET /api/patient/doctor/{patientId}`.
  static Future<DoctorInfoModel?> getAssignedDoctor(int patientId) async {
    try {
      log('Fetching assigned doctor for patient $patientId',
          name: 'PatientApiService');

      final response = await DioClient.instance.get(
        ApiEndpoints.patientDoctor(patientId),
      );

      // 204 No Content → no doctor assigned yet
      if (response.statusCode == 204 || response.data == null) {
        log('No doctor assigned to patient $patientId',
            name: 'PatientApiService');
        return null;
      }

      final doctor =
          DoctorInfoModel.fromJson(response.data as Map<String, dynamic>);
      log('Assigned doctor: ${doctor.fullName}', name: 'PatientApiService');
      return doctor;
    } on DioException catch (e) {
      // 204 can also surface as a DioException in some interceptor setups
      if (e.response?.statusCode == 204) return null;
      log('Failed to fetch assigned doctor: ${e.message}',
          name: 'PatientApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}
