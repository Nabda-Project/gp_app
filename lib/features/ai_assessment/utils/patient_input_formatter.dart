// Utility to format patient-submitted assessment data into
// readable Arabic sections for display in the report UI and PDF.
import 'report_formatter.dart';

class PatientInputFormatter {
  PatientInputFormatter._();

  // ── History field labels ────────────────────────────────────────────────
  static const _historyLabels = <String, String>{
    'known_cardiac': 'التشخيصات السابقة',
    'known_cardiac_other': 'تشخيص آخر',
    'prior_workup': 'الفحوصات السابقة',
    'chronic_conditions': 'الأمراض المزمنة',
    'medications': 'الأدوية',
    'med_adherence': 'الالتزام بالأدوية',
    'family_history': 'تاريخ عائلي لمرض القلب',
    'lifestyle': 'نمط الحياة',
  };

  // ── Symptom code → Arabic label ─────────────────────────────────────────
  static const _symptomLabels = <String, String>{
    'palpitations': 'خفقان / تسارع في ضربات القلب',
    'irregular': 'عدم انتظام / إحساس بتوقف لحظي',
    'chest_pain': 'ألم أو ضغط أو ضيق في الصدر',
    'heart_pain': 'ألم في منطقة القلب',
    'stabs': 'نغزات / وخز / طعنات',
    'dyspnea': 'ضيق أو صعوبة في التنفس',
    'dizziness': 'دوخة / دوار',
    'fainting': 'إغماء أو فقدان وعي',
    'fatigue': 'تعب / إرهاق',
    'sweating': 'تعرق',
    'nausea': 'غثيان / قيء',
    'arm_radiation': 'ألم ينتشر إلى الذراع اليسرى',
    'tingling': 'تنميل أو خدر في الأطراف',
    'tremor': 'رجفة / ارتعاش',
    'cold_extremities': 'برودة في الأطراف',
    'other': 'عرض آخر',
  };

  // ── Detail field labels ─────────────────────────────────────────────────
  static const _detailLabels = <String, String>{
    'severity': 'الشدة',
    'duration_general': 'منذ متى',
    'pattern': 'النمط',
    'episode_duration': 'مدة النوبة',
    'triggers': 'المحفزات',
    'relieving_factors': 'ما يخفف العرض',
    'location': 'مكان الألم',
    'radiation': 'الانتشار',
    'exertional': 'يزيد مع المجهود',
    'quality': 'وصف الإحساس',
    'rate_feel': 'وصف الإحساس',
    'skip_or_extra': 'وصف الإحساس',
    'orthopnea': 'يزداد عند الاستلقاء',
    'exertion_level': 'مستوى الجهد المسبب',
    'type': 'نوع الدوخة',
    'full_loss': 'فقدان الوعي',
    'recovery_time': 'وقت التعافي',
    'side': 'الجانب',
    'exertional_change': 'يزداد مع المجهود',
  };

  // ── Red flag labels ─────────────────────────────────────────────────────
  static const _redFlagLabels = <String, String>{
    'syncope_exertion': 'إغماء أثناء الرياضة أو المجهود',
    'exertional_chest': 'ألم صدر يزداد مع المجهود',
  };

  // ── Value translations ──────────────────────────────────────────────────
  static const _values = <String, String>{
    // Cardiac diagnoses
    'none': 'لا يوجد',
    'mvp': 'ارتخاء في الصمام الميترالي',
    'hole_congenital': 'ثقب في القلب / عيب خلقي',
    'enlarged': 'تضخم في القلب',
    'arrhythmia': 'عدم انتظام ضربات القلب',
    'prior_mi_stroke': 'جلطة أو ذبحة سابقة',
    'catheter_stent': 'قسطرة / دعامة / عملية قلب',
    // Workups
    'ecg': 'رسم قلب',
    'echo': 'إيكو',
    'holter': 'هولتر',
    'stress': 'رسم قلب بالمجهود',
    'cath': 'قسطرة تشخيصية',
    // Chronic conditions
    'htn': 'ارتفاع ضغط الدم',
    'low_bp': 'انخفاض ضغط الدم',
    'dm': 'السكري',
    'chol': 'ارتفاع الكوليسترول',
    'thyroid': 'اضطراب الغدة الدرقية',
    'anemia': 'فقر دم / أنيميا',
    'ibs': 'القولون العصبي',
    'reflux': 'ارتجاع / حموضة',
    // Lifestyle
    'smoker': 'مدخن حالياً',
    'ex_smoker': 'مدخن سابق',
    'heavy_caffeine': 'كافيين بكثرة',
    'gym': 'يمارس الرياضة بانتظام',
    'supplements': 'منشطات أو هرمونات',
    // Med adherence
    'compliant': 'ملتزم بالدواء',
    'recently_stopped': 'توقف مؤخراً',
    'irregular': 'جرعات غير منتظمة',
    // Severity
    'mild': 'خفيفة',
    'moderate': 'متوسطة',
    'severe': 'شديدة',
    'unbearable': 'لا تُحتمل',
    // Duration
    'today': 'بدأت اليوم',
    'days': 'منذ أيام',
    'weeks': 'منذ أسابيع',
    'months': 'منذ شهور',
    'years': 'منذ سنوات',
    'since_childhood': 'منذ الطفولة',
    // Pattern
    'episodic': 'نوبات تأتي وتذهب',
    'continuous': 'مستمر',
    'single': 'حدث مرة واحدة',
    // Episode duration
    'seconds': 'ثوانٍ',
    'minutes_short': 'دقائق قليلة',
    'minutes_long': 'من 5 إلى 30 دقيقة',
    'hours': 'ساعات',
    // Triggers
    'sudden': 'فجأة بدون سبب',
    'night': 'في الليل',
    'sleep': 'أثناء النوم',
    'waking': 'عند الاستيقاظ',
    'exertion': 'عند المجهود',
    'rest': 'عند الراحة',
    'after_meals': 'بعد الأكل',
    'emotional': 'عند التوتر أو الغضب',
    'after_caffeine': 'بعد القهوة / الشاي',
    'after_smoking': 'بعد التدخين',
    'cold_water': 'مع الماء البارد',
    'menstruation': 'مع الدورة الشهرية',
    // Relieving factors
    'medication': 'الدواء',
    'position_change': 'تغيير الوضعية',
    'deep_breathing': 'التنفس العميق',
    'nothing': 'لا شيء يخففه',
    'self_resolves': 'يزول من تلقاء نفسه',
    // Location
    'left_precordial': 'منطقة القلب (اليسار)',
    'central': 'منتصف الصدر',
    'right': 'اليمين',
    'moving': 'عشوائية تتنقل',
    // Radiation
    'no_radiation': 'لا ينتشر',
    'left_arm': 'الذراع / الكتف / اليد اليسرى',
    'right_arm': 'الذراع / الكتف / اليد اليمنى',
    'back': 'الظهر / بين الكتفين',
    'neck': 'الرقبة',
    'jaw': 'الفك أو الأسنان',
    'upper_abdomen': 'أعلى البطن',
    // Yes/No
    'yes': 'نعم',
    'no': 'لا',
    'not_sure': 'لست متأكداً',
    'unknown': 'لا أعرف',
    // Palpitation types
    'fast_regular': 'سريعة ومنتظمة',
    'fast_irregular': 'سريعة وغير منتظمة',
    'forceful': 'قوية في الصدر',
    'neck_pounding': 'أشعر بها في الرقبة',
    // Irregular types
    'pause_then_thump': 'توقف لحظي ثم عودة',
    'extra_beat': 'ضربة إضافية خارج النظام',
    'full_irregular': 'اضطراب كامل في الإيقاع',
    'svt_like': 'تسارع مفاجئ ثم عودة',
    // Dyspnea
    'yes_orthopnea': 'نعم، يحتاج وسائد إضافية',
    'moderate_exertion': 'عند المشي السريع / صعود الدرج',
    'minimal_exertion': 'عند أدنى مجهود',
    'at_rest': 'عند الراحة التامة',
    'unrelated': 'لا يرتبط بالمجهود',
    // Dizziness
    'vertigo': 'إحساس بالدوران',
    'lightheaded': 'ضبابية / عدم وضوح',
    'presyncope': 'إحساس بالإغماء الوشيك',
    'imbalance': 'عدم اتزان عند المشي',
    // Fainting
    'complete_loss': 'فقد الوعي تماماً',
    'near_syncope': 'كاد يحدث',
    'minutes': 'دقيقة أو أكثر',
    'required_intervention': 'استدعى التدخل',
    // Arm radiation side
    'left_only': 'اليسار فقط',
    'right_only': 'اليمين فقط',
    'both': 'الجانبين',
    // Fatigue
    'slightly': 'قليلاً',
    // Quality
    'pressure': 'ضغط / ثقل',
    'burning': 'حرقة / حموضة',
    'stabbing': 'طعنة / وخز حاد',
    'tightness': 'شد / تشنج',
    'vague': 'إحساس غريب يصعب وصفه',
  };

  /// Translate a single code value to Arabic.
  static String translateValue(String code) {
    final lower = code.trim().toLowerCase();
    return _values[lower] ?? ReportFormatter.translateValue(code);
  }

  /// Translate a list of codes to Arabic comma-separated string.
  static String translateList(List list) {
    final items = list
        .map((e) => translateValue(e.toString()))
        .where((s) => s.isNotEmpty)
        .toList();
    return items.join('، ');
  }

  /// Try to parse `patientInput` into structured data.
  /// Returns a Map if successful, null otherwise.
  static Map<String, dynamic>? tryParseInput(String raw) {
    if (raw.trim().isEmpty) return null;

    // Try JSON first
    final jsonParsed = ReportFormatter.tryParseJson(raw);
    if (jsonParsed is Map<String, dynamic>) return jsonParsed;

    // Try to parse ChatbotSubmissionRequest(...) format
    if (raw.contains('ChatbotSubmissionRequest(')) {
      return _parseChatbotString(raw);
    }

    return null;
  }

  /// Build display sections from the structured assessment data.
  /// Returns a list of [title, content] pairs suitable for rendering.
  static List<MapEntry<String, dynamic>> buildDisplaySections(
      Map<String, dynamic> data) {
    final sections = <MapEntry<String, dynamic>>[];

    // 1. History
    final history = data['history'] as Map<String, dynamic>?;
    if (history != null && history.isNotEmpty) {
      final rows = <MapEntry<String, String>>[];
      for (final e in history.entries) {
        if (ReportFormatter.isEmpty(e.value)) continue;
        if (e.key == 'known_cardiac' &&
            e.value is List &&
            (e.value as List).length == 1 &&
            (e.value as List)[0] == 'none') {
          continue;
        }
        if (e.key == 'lifestyle' &&
            e.value is List &&
            (e.value as List).length == 1 &&
            (e.value as List)[0] == 'none') {
          continue;
        }
        if (e.key == 'prior_workup' &&
            e.value is List &&
            (e.value as List).length == 1 &&
            (e.value as List)[0] == 'none') {
          continue;
        }
        if (e.key == 'chronic_conditions' &&
            e.value is List &&
            (e.value as List).length == 1 &&
            (e.value as List)[0] == 'none') {
          continue;
        }

        final label = _historyLabels[e.key] ?? e.key;
        final display = e.value is List
            ? translateList(e.value as List)
            : translateValue(e.value.toString());
        if (display.isNotEmpty && display != 'لا يوجد') {
          rows.add(MapEntry(label, display));
        }
      }
      if (rows.isNotEmpty) {
        sections.add(MapEntry('التاريخ المرضي', rows));
      }
    }

    // 2. Symptom Selection
    final symSel = data['symptomSelection'] ?? data['symptom_selection'];
    if (symSel is Map) {
      final chosen = symSel['chosen'];
      if (chosen is List && chosen.isNotEmpty) {
        final labels = chosen
            .map((c) => _symptomLabels[c.toString()] ?? c.toString())
            .toList();
        sections.add(MapEntry('الأعراض المختارة', labels));
      }
    }

    // 3. Symptom Details
    final symDetail = data['symptomDetail'] ?? data['symptom_detail'];
    if (symDetail is Map) {
      for (final symptomEntry in symDetail.entries) {
        if (ReportFormatter.isEmpty(symptomEntry.value)) continue;
        final symptomCode = symptomEntry.key;
        final symptomName =
            _symptomLabels[symptomCode] ?? symptomCode;
        final detail = symptomEntry.value;
        if (detail is Map) {
          final rows = <MapEntry<String, String>>[];
          for (final f in detail.entries) {
            if (ReportFormatter.isEmpty(f.value)) continue;
            final label = _detailLabels[f.key] ?? f.key;
            final display = f.value is List
                ? translateList(f.value as List)
                : translateValue(f.value.toString());
            if (display.isNotEmpty) {
              rows.add(MapEntry(label, display));
            }
          }
          if (rows.isNotEmpty) {
            sections.add(MapEntry(symptomName, rows));
          }
        }
      }
    }

    // 4. Red Flags
    final redFlags = data['redFlags'] ?? data['red_flags'];
    if (redFlags is Map && redFlags.isNotEmpty) {
      final rows = <MapEntry<String, String>>[];
      for (final e in redFlags.entries) {
        if (ReportFormatter.isEmpty(e.value)) continue;
        final label = _redFlagLabels[e.key] ?? e.key;
        final display = translateValue(e.value.toString());
        rows.add(MapEntry(label, display));
      }
      if (rows.isNotEmpty) {
        sections.add(MapEntry('علامات الخطورة', rows));
      }
    }

    // 5. Free Text
    final freeText = data['freeText'] ?? data['free_text'];
    if (freeText is Map) {
      final additional = freeText['additional']?.toString().trim() ?? '';
      if (additional.isNotEmpty &&
          additional != 'لا' &&
          additional.toLowerCase() != 'no') {
        sections.add(MapEntry('ملاحظات إضافية', additional));
      }
    } else if (freeText is String && freeText.trim().isNotEmpty) {
      final trimmed = freeText.trim();
      if (trimmed != 'لا' && trimmed.toLowerCase() != 'no') {
        sections.add(MapEntry('ملاحظات إضافية', trimmed));
      }
    }

    return sections;
  }

  /// Best-effort parsing of ChatbotSubmissionRequest(...) toString() format.
  static Map<String, dynamic>? _parseChatbotString(String raw) {
    // This is a rough heuristic parser - for display only
    try {
      // Remove wrapper
      var body = raw;
      final startIdx = raw.indexOf('(');
      final endIdx = raw.lastIndexOf(')');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        body = raw.substring(startIdx + 1, endIdx);
      }
      // Try to convert to JSON-like and parse
      // This is best-effort; if it fails we return null
      body = body
          .replaceAll('=', ':')
          .replaceAll('{', '{"')
          .replaceAll('}', '"}')
          .replaceAll(', ', '","')
          .replaceAll(':', '":"')
          .replaceAll('[', '["')
          .replaceAll(']', '"]');
      // Too risky - return null and let the caller handle gracefully
      return null;
    } catch (_) {
      return null;
    }
  }
}
