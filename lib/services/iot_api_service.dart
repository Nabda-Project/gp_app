import 'dart:developer';
import 'package:dio/dio.dart';
import '../core/api/dio_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exceptions.dart';
import '../models/health_metric_model.dart';
import '../models/metric_request.dart';
import '../models/daily_summary_model.dart';
import '../models/hourly_summary_model.dart';

/// Handles calls to back-end `/api/iot/*` endpoints.
class IoTApiService {
  IoTApiService._();

  /// Upload a health metric for a patient.
  ///
  /// Corresponds to `POST /api/iot/upload/{patientId}`.
  static Future<HealthMetricModel> uploadMetric(int patientId, MetricRequest request) async {
    try {
      log('Uploading metric for patient $patientId', name: 'IoTApiService');
      final response = await DioClient.instance.post(
        ApiEndpoints.uploadMetric(patientId),
        data: request.toJson(),
      );
      final metric = HealthMetricModel.fromJson(response.data as Map<String, dynamic>);
      log('Metric uploaded successfully', name: 'IoTApiService');
      return metric;
    } on DioException catch (e) {
      log('Metric upload failed: ${e.message}', name: 'IoTApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Get the latest health metric for a patient.
  ///
  /// Corresponds to `GET /api/iot/latest/{patientId}`.
  /// Returns `null` if the patient has no readings yet.
  static Future<HealthMetricModel?> getLatest(int patientId) async {
    try {
      log('Fetching latest metric for patient $patientId', name: 'IoTApiService');
      final response = await DioClient.instance.get(
        ApiEndpoints.latestMetric(patientId),
      );

      if (response.data == null) return null;
      final metric = HealthMetricModel.fromJson(response.data as Map<String, dynamic>);
      log('Fetched latest metric (id: ${metric.id})', name: 'IoTApiService');
      return metric;
    } on DioException catch (e) {
      // 404 means no readings exist — return null gracefully
      if (e.response?.statusCode == 404) {
        log('No metrics found for patient $patientId', name: 'IoTApiService');
        return null;
      }
      log('Latest metric fetch failed: ${e.message}', name: 'IoTApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Get health metric history for a patient.
  ///
  /// Corresponds to `GET /api/iot/history/{patientId}`.
  /// Returns newest-first (back-end orders by timestamp DESC).
  static Future<List<HealthMetricModel>> getHistory(int patientId, {int days = 7}) async {
    try {
      log('Fetching metric history for patient $patientId', name: 'IoTApiService');
      final response = await DioClient.instance.get(
        ApiEndpoints.metricHistory(patientId),
        queryParameters: {'days': days},
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

  /// Get daily-aggregated metric summaries for chart rendering.
  ///
  /// Corresponds to `GET /api/iot/summary/{patientId}?days=N`.
  /// Returns oldest-first (ascending by date).
  static Future<List<DailySummaryModel>> getDailySummary(int patientId, {int days = 7}) async {
    try {
      log('Fetching daily summary for patient $patientId ($days days)', name: 'IoTApiService');
      final response = await DioClient.instance.get(
        ApiEndpoints.metricSummary(patientId),
        queryParameters: {'days': days},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final summaries = data
          .map((item) => DailySummaryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      log('Fetched ${summaries.length} daily summaries', name: 'IoTApiService');
      return summaries;
    } on DioException catch (e) {
      log('Daily summary fetch failed: ${e.message}', name: 'IoTApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }

  /// Get hourly-aggregated metric summaries for chart rendering (24H mode).
  ///
  /// Corresponds to `GET /api/iot/summary/hourly/{patientId}?hours=N`.
  /// Returns oldest-first (ascending by date/time).
  static Future<List<HourlySummaryModel>> getHourlySummary(int patientId, {int hours = 24}) async {
    try {
      log('Fetching hourly summary for patient $patientId ($hours hours)', name: 'IoTApiService');
      final response = await DioClient.instance.get(
        ApiEndpoints.hourlySummary(patientId),
        queryParameters: {'hours': hours},
      );

      final List<dynamic> data = response.data as List<dynamic>;
      final summaries = data
          .map((item) => HourlySummaryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      log('Fetched ${summaries.length} hourly summaries', name: 'IoTApiService');
      return summaries;
    } on DioException catch (e) {
      log('Hourly summary fetch failed: ${e.message}', name: 'IoTApiService');
      if (e.error is ApiException) throw e.error!;
      rethrow;
    }
  }
}
