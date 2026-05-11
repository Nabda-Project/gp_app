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
  final String? patientRequestData;
  final String? patientName;
  final int? patientAge;
  final String? patientGender;
  final double? patientHeight;
  final double? patientWeight;
  final String aiReport;
  final DateTime createdAt;

  AiConsultResponse({
    required this.id,
    required this.patientId,
    required this.patientInput,
    this.patientRequestData,
    this.patientName,
    this.patientAge,
    this.patientGender,
    this.patientHeight,
    this.patientWeight,
    required this.aiReport,
    required this.createdAt,
  });

  factory AiConsultResponse.fromJson(Map<String, dynamic> json) {
    return AiConsultResponse(
      id: json['id'] as int? ?? 0,
      patientId: json['patientId'] as int? ?? 0,
      patientInput: json['patientInput'] as String? ?? '',
      patientRequestData: json['patientRequestData'] as String?,
      patientName: json['patientName'] as String?,
      patientAge: json['patientAge'] as int?,
      patientGender: json['patientGender'] as String?,
      patientHeight: (json['patientHeight'] as num?)?.toDouble(),
      patientWeight: (json['patientWeight'] as num?)?.toDouble(),
      aiReport: json['aiReport'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

