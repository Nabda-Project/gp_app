// Utility helpers for formatting and translating AI report data.
//
// Translates JSON keys / values to Arabic, checks emptiness,
// and safely parses the raw `aiReport` string.
import 'dart:convert';

class ReportFormatter {
  ReportFormatter._();

  // ── Section key → Arabic title ───────────────────────────────────────────
  static const Map<String, String> _sectionTitles = {
    'symptoms': 'الأعراض',
    'old_diagnosis': 'التشخيصات السابقة',
    'medication': 'الأدوية',
    'medications': 'الأدوية',
    'notes': 'ملاحظات',
    'recommendations': 'التوصيات',
    'risk_factors': 'عوامل الخطورة',
    'summary': 'الملخص',
    'diagnosis': 'التقييم المبدئي',
    'warnings': 'تنبيهات',
    'next_steps': 'الخطوات التالية',
    'risk': 'عوامل الخطورة',
    'risk_level': 'مستوى الخطورة',
    'urgency': 'مستوى الاستعجال',
    'differentials': 'التشخيصات التفاضلية',
    'red_flags': 'علامات التحذير',
    'follow_up': 'متابعة',
    'history': 'التاريخ المرضي',
    'lifestyle': 'نمط الحياة',
    'vital_signs': 'العلامات الحيوية',
    'lab_results': 'نتائج المختبر',
    'imaging': 'الأشعة والتصوير',
    'plan': 'الخطة العلاجية',
    'referral': 'الإحالة',
    'referrals': 'الإحالات',
  };

  // ── Field key → Arabic label ─────────────────────────────────────────────
  static const Map<String, String> _fieldLabels = {
    'symptom': 'العرض',
    'severity': 'الشدة',
    'duration': 'المدة',
    'frequency': 'التكرار',
    'trigger': 'المحفز',
    'triggers': 'المحفزات',
    'relieving_factors': 'ما يخفف العرض',
    'quality': 'طبيعة الألم',
    'radiation': 'انتشار الألم',
    'notes': 'ملاحظات',
    'name': 'الاسم',
    'dose': 'الجرعة',
    'dosage': 'الجرعة',
    'description': 'الوصف',
    'type': 'النوع',
    'location': 'الموقع',
    'onset': 'وقت البداية',
    'status': 'الحالة',
    'result': 'النتيجة',
    'date': 'التاريخ',
    'value': 'القيمة',
    'unit': 'الوحدة',
    'reason': 'السبب',
    'comment': 'تعليق',
    'details': 'التفاصيل',
  };

  // ── Known value translations ─────────────────────────────────────────────
  static const Map<String, String> _valueTranslations = {
    'mild': 'خفيف',
    'moderate': 'متوسط',
    'severe': 'شديد',
    'unbearable': 'لا يُحتمل',
    'episodic': 'يأتي في نوبات',
    'continuous': 'مستمر',
    'single': 'حدث مرة واحدة',
    'yes': 'نعم',
    'no': 'لا',
    'not_sure': 'لست متأكداً',
    'true': 'نعم',
    'false': 'لا',
    'none': 'لا يوجد',
    'low': 'منخفض',
    'high': 'مرتفع',
    'normal': 'طبيعي',
    'abnormal': 'غير طبيعي',
    'positive': 'إيجابي',
    'negative': 'سلبي',
  };

  // ── Public API ───────────────────────────────────────────────────────────

  /// Translate a section key (e.g. `symptoms`) to an Arabic title.
  static String translateSection(String key) {
    final lower = key.trim().toLowerCase();
    if (_sectionTitles.containsKey(lower)) return _sectionTitles[lower]!;
    // Fallback: replace underscores with spaces and capitalise
    return lower.replaceAll('_', ' ');
  }

  /// Translate a field key (e.g. `severity`) to an Arabic label.
  static String translateField(String key) {
    final lower = key.trim().toLowerCase();
    if (_fieldLabels.containsKey(lower)) return _fieldLabels[lower]!;
    if (_sectionTitles.containsKey(lower)) return _sectionTitles[lower]!;
    return lower.replaceAll('_', ' ');
  }

  /// Translate a known value (e.g. `severe` → `شديد`).
  /// Returns the original value if no translation exists.
  static String translateValue(String value) {
    final lower = value.trim().toLowerCase();
    return _valueTranslations[lower] ?? value;
  }

  /// Returns `true` when [value] should be considered empty / not displayable.
  static bool isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      return trimmed.isEmpty ||
          trimmed == 'null' ||
          trimmed == '[]' ||
          trimmed == '{}' ||
          trimmed == 'n/a' ||
          trimmed == 'none';
    }
    if (value is List) {
      if (value.isEmpty) return true;
      // A list of maps where every map has only empty values
      if (value.every((e) => e is Map && _isMapAllEmpty(e))) return true;
      return false;
    }
    if (value is Map) return _isMapAllEmpty(value);
    return false;
  }

  /// Try to parse [raw] as JSON. Returns the decoded object or `null`.
  static dynamic tryParseJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded;
    } catch (_) {
      return null;
    }
  }

  /// Format a [DateTime] as an Arabic date string, e.g. `11 مايو 2026`.
  static String formatDateArabic(DateTime dt) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  /// Convert a flat value to a display string.
  /// Translates known values automatically.
  static String valueToString(dynamic value) {
    if (value is bool) return value ? 'نعم' : 'لا';
    if (value is num) return value.toString();
    if (value is String) return translateValue(value);
    return value.toString();
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static bool _isMapAllEmpty(Map map) {
    return map.values.every((v) => isEmpty(v));
  }
}
