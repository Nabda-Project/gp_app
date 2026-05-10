/// Data models for the cardiac AI assessment feature.

enum QuestionType { number, choice, multiChoice, text }

class QuestionOption {
  final String label;
  final String value;

  const QuestionOption({required this.label, required this.value});
}

class DependsOn {
  final String field;
  final String? equals;
  final List<String>? containsAny;
  final List<String>? notContainsAny;
  final List<String>? notTextIn;

  const DependsOn({
    required this.field,
    this.equals,
    this.containsAny,
    this.notContainsAny,
    this.notTextIn,
  });

  bool evaluate(Map<String, dynamic> data) {
    final val = _getNestedValue(field, data);

    if (equals != null) {
      return val == equals;
    }
    if (containsAny != null) {
      if (val is List) {
        return val.any((v) => containsAny!.contains(v));
      }
      return containsAny!.contains(val);
    }
    if (notContainsAny != null) {
      if (val is List) {
        return !val.any((v) => notContainsAny!.contains(v));
      }
      return !notContainsAny!.contains(val);
    }
    if (notTextIn != null) {
      if (val == null) return false;
      final lower = val.toString().trim().toLowerCase();
      return !notTextIn!.any((s) => lower.contains(s.toLowerCase()));
    }

    return true;
  }

  static dynamic _getNestedValue(String path, Map<String, dynamic> data) {
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}

class AssessmentQuestion {
  final String field;
  final String question;
  final QuestionType type;
  final List<QuestionOption>? options;
  final double? min;
  final double? max;
  final DependsOn? dependsOn;
  final bool hasNoneOption; // For multi-choice "none" toggle behavior

  const AssessmentQuestion({
    required this.field,
    required this.question,
    required this.type,
    this.options,
    this.min,
    this.max,
    this.dependsOn,
    this.hasNoneOption = false,
  });
}

class AiConsultResponse {
  final int id;
  final int patientId;
  final String patientInput;
  final String aiReport;
  final DateTime createdAt;

  AiConsultResponse({
    required this.id,
    required this.patientId,
    required this.patientInput,
    required this.aiReport,
    required this.createdAt,
  });

  factory AiConsultResponse.fromJson(Map<String, dynamic> json) {
    return AiConsultResponse(
      id: json['id'] as int? ?? 0,
      patientId: json['patientId'] as int? ?? 0,
      patientInput: json['patientInput'] as String? ?? '',
      aiReport: json['aiReport'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Response from the structured assessment endpoint.
/// POST /api/ai/consult/{patientId}
/// Returns the merged assessment data with demographics from DB.
class ChatbotMergedResponse {
  final int patientId;
  final Map<String, dynamic> demographics;
  final Map<String, dynamic> history;
  final Map<String, dynamic> symptomSelection;
  final Map<String, dynamic> symptomDetail;
  final List<dynamic> otherSymptoms;
  final Map<String, dynamic> redFlags;
  final Map<String, dynamic> freeText;

  ChatbotMergedResponse({
    required this.patientId,
    required this.demographics,
    required this.history,
    required this.symptomSelection,
    required this.symptomDetail,
    required this.otherSymptoms,
    required this.redFlags,
    required this.freeText,
  });

  factory ChatbotMergedResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotMergedResponse(
      patientId: json['patientId'] as int? ?? 0,
      demographics: (json['demographics'] as Map<String, dynamic>?) ?? {},
      history: (json['history'] as Map<String, dynamic>?) ?? {},
      symptomSelection: (json['symptom_selection'] as Map<String, dynamic>?) ?? {},
      symptomDetail: (json['symptom_detail'] as Map<String, dynamic>?) ?? {},
      otherSymptoms: (json['other_symptoms'] as List<dynamic>?) ?? [],
      redFlags: (json['red_flags'] as Map<String, dynamic>?) ?? {},
      freeText: (json['free_text'] as Map<String, dynamic>?) ?? {},
    );
  }
}
