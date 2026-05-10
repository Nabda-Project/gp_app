/// API service for AI assessment endpoints.
import 'dart:developer';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../models/assessment_models.dart';

class AiAssessmentApiService {
  AiAssessmentApiService._();

  /// Submit the full assessment JSON.
  /// POST /api/ai/consult/{patientId}
  /// Returns the merged assessment with demographics from DB.
  static Future<ChatbotMergedResponse> submitAssessment({
    required int patientId,
    required Map<String, dynamic> assessmentData,
  }) async {
    try {
      final response = await DioClient.instance.post(
        '/ai/consult/$patientId',
        data: assessmentData,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 6),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ChatbotMergedResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception('Unexpected status code: ${response.statusCode}');
    } on DioException catch (e) {
      log('AI consult failed: ${e.message}', name: 'AiAssessmentApi');
      rethrow;
    }
  }

  /// Fetch the patient's past AI reports.
  /// GET /api/ai/my-reports
  static Future<List<AiConsultResponse>> getMyReports() async {
    try {
      final response = await DioClient.instance.get('/ai/my-reports');

      if (response.statusCode == 200) {
        final list = response.data as List<dynamic>;
        return list
            .map((e) =>
                AiConsultResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Unexpected status code: ${response.statusCode}');
    } on DioException catch (e) {
      log('Fetch reports failed: ${e.message}', name: 'AiAssessmentApi');
      rethrow;
    }
  }
}
