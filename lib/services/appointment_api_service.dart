import 'dart:developer';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exceptions.dart';
import '../models/appointment_model.dart';

class AppointmentApiService {
  AppointmentApiService._();

  static Future<AppointmentModel> scheduleAppointment({
    required int doctorId,
    required int patientId,
    required DateTime date,
    String? reason,
  }) async {
    try {
      final response = await DioClient.instance.post(
        ApiEndpoints.scheduleAppointment,
        data: {
          'doctorId': doctorId,
          'patientId': patientId,
          'appointmentDate': date.toUtc().toIso8601String(),
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      log('Failed to schedule appointment: ${e.message}', name: 'AppointmentApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  static Future<List<AppointmentModel>> getDoctorAppointments(int doctorId) async {
    try {
      final response = await DioClient.instance.get(
        ApiEndpoints.doctorAppointments(doctorId),
      );
      final list = (response.data as List).cast<Map<String, dynamic>>();
      return list.map((json) => AppointmentModel.fromJson(json)).toList();
    } on DioException catch (e) {
      log('Failed to get doctor appointments: ${e.message}', name: 'AppointmentApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  static Future<AppointmentModel?> getNextAppointment(int patientId) async {
    try {
      final response = await DioClient.instance.get(
        ApiEndpoints.nextAppointment(patientId),
      );
      if (response.statusCode == 204 || response.data == null || response.data.toString().isEmpty) {
        return null;
      }
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 204) return null;
      log('Failed to get next appointment: ${e.message}', name: 'AppointmentApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  static Future<AppointmentModel> updateAppointmentStatus(int appointmentId, String status) async {
    try {
      final response = await DioClient.instance.patch(
        ApiEndpoints.updateAppointmentStatus(appointmentId),
        data: {'status': status},
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      log('Failed to update appointment status: ${e.message}', name: 'AppointmentApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}
