import 'dart:developer';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exceptions.dart';
import '../models/health_metric_model.dart';
import '../models/metric_request.dart';

/// Handles calls to back-end `/api/iot/*` endpoints.
class IoTApiService {
  IoTApiService._();

  /// Upload a health metric for a patient.
  ///
  /// Corresponds to `POST /api/iot/upload/{patientId}`.
  static Future<void> uploadMetric(int patientId, MetricRequest request) async {
    try {
      log('Uploading metric for patient $patientId', name: 'IoTApiService');
      await DioClient.instance.post(
        ApiEndpoints.uploadMetric(patientId),
        data: request.toJson(),
      );
      log('Metric uploaded successfully', name: 'IoTApiService');
    } on DioException catch (e) {
      log('Metric upload failed: ${e.message}', name: 'IoTApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Get health metric history for a patient.
  ///
  /// Corresponds to `GET /api/iot/history/{patientId}`.
  /// Returns newest-first (back-end orders by timestamp DESC).
  static Future<List<HealthMetricModel>> getHistory(int patientId) async {
    try {
      log('Fetching metric history for patient $patientId', name: 'IoTApiService');
      final response = await DioClient.instance.get(
        ApiEndpoints.metricHistory(patientId),
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final metrics = data
          .map((item) => HealthMetricModel.fromJson(item as Map<String, dynamic>))
          .toList();

      log('Fetched ${metrics.length} metrics', name: 'IoTApiService');
      return metrics;
    } on DioException catch (e) {
      log('Metric history fetch failed: ${e.message}', name: 'IoTApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}
