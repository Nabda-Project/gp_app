/// API service for AI assessment endpoints.
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/assessment_models.dart';

class AiAssessmentApiService {
  AiAssessmentApiService._();

  /// Submit the full assessment JSON.
  /// POST /api/ai/consult/{patientId}
  /// Returns AiConsultResponse (id, patientId, patientInput, aiReport, createdAt).
  static Future<AiConsultResponse> submitAssessment({
    required int patientId,
    required Map<String, dynamic> assessmentData,
  }) async {
    final endpoint = '/ai/consult/$patientId';

    // TODO: Remove debug logs before production
    log(
      'AI_ASSESSMENT_SUBMIT — endpoint: $endpoint, patientId: $patientId',
      name: 'AI_ASSESSMENT_DEBUG',
    );
    log(
      'AI_ASSESSMENT_FINAL_JSON:\n${const JsonEncoder.withIndent('  ').convert(assessmentData)}',
      name: 'AI_ASSESSMENT_DEBUG',
    );

    try {
      final response = await DioClient.instance.post(
        endpoint,
        data: assessmentData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 6),
        ),
      );

      // TODO: Remove debug logs before production
      log(
        'AI_ASSESSMENT_RESPONSE — status: ${response.statusCode}',
        name: 'AI_ASSESSMENT_DEBUG',
      );
      log(
        'AI_ASSESSMENT_RESPONSE_BODY — ${_summarize(response.data)}',
        name: 'AI_ASSESSMENT_DEBUG',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AiConsultResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception('Unexpected status code: ${response.statusCode}');
    } on DioException catch (e) {
      // TODO: Remove debug logs before production
      log(
        'AI_ASSESSMENT_ERROR — status: ${e.response?.statusCode}, message: ${e.message}',
        name: 'AI_ASSESSMENT_DEBUG',
      );
      rethrow;
    }
  }

  /// Fetch the patient's past AI reports.
  /// GET /api/ai/my-reports
  static Future<List<AiConsultResponse>> getMyReports() async {
    // TODO: Remove debug logs before production
    log('AI_REPORTS_FETCH — endpoint: /ai/my-reports', name: 'AI_ASSESSMENT_DEBUG');

    try {
      final response = await DioClient.instance.get('/ai/my-reports');

      log(
        'AI_REPORTS_RESPONSE — status: ${response.statusCode}, count: ${(response.data as List?)?.length ?? 0}',
        name: 'AI_ASSESSMENT_DEBUG',
      );

      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        return list
            .map((e) =>
                AiConsultResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Unexpected status code: ${response.statusCode}');
    } on DioException catch (e) {
      log('AI_REPORTS_ERROR — ${e.message}', name: 'AI_ASSESSMENT_DEBUG');
      rethrow;
    }
  }

  /// Fetch a specific patient's AI reports for a doctor.
  /// GET /api/ai/history/{patientId}
  static Future<List<AiConsultResponse>> getPatientReportsForDoctor(int patientId) async {
    log('AI_REPORTS_FETCH_DOCTOR — endpoint: /ai/history/$patientId', name: 'AI_ASSESSMENT_DEBUG');

    try {
      final response = await DioClient.instance.get('/ai/history/$patientId');

      log(
        'AI_REPORTS_DOCTOR_RESPONSE — status: ${response.statusCode}, count: ${(response.data as List?)?.length ?? 0}',
        name: 'AI_ASSESSMENT_DEBUG',
      );

      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        return list
            .map((e) =>
                AiConsultResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Unexpected status code: ${response.statusCode}');
    } on DioException catch (e) {
      log('AI_REPORTS_DOCTOR_ERROR — ${e.message}', name: 'AI_ASSESSMENT_DEBUG');
      rethrow;
    }
  }

  /// Summarize response data for debug logging (truncates long reports).
  static String _summarize(dynamic data) {
    if (data == null) return 'null';
    if (data is Map) {
      final id = data['id'];
      final reportLen = (data['aiReport'] as String?)?.length ?? 0;
      return 'id=$id, aiReport.length=$reportLen';
    }
    final str = data.toString();
    return str.length > 200 ? '${str.substring(0, 200)}...' : str;
  }
}
