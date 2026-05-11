/// All cardiac assessment questions hardcoded from med.py.
/// English codes are preserved exactly. Arabic labels match med.py.
import '../models/assessment_models.dart';

// ─── Symptom Labels (code -> Arabic label) ───────────────────────────────────
const Map<String, String> symptomLabels = {
  'palpitations': 'خفقان / تسارع في ضربات القلب',
  'irregular': 'عدم انتظام / إحساس بتوقف لحظي',
  'chest_pain': 'ألم أو ضغط أو ضيق في الصدر',
  'heart_pain': 'ألم في منطقة القلب تحديداً',
  'stabs': 'نغزات / وخز / طعنات',
  'dyspnea': 'ضيق أو صعوبة في التنفس',
  'dizziness': 'دوخة / دوار / عدم اتزان',
  'fainting': 'إغماء أو فقدان وعي',
  'fatigue': 'تعب / إرهاق / ضعف عام',
  'sweating': 'تعرق (خصوصاً عرق بارد)',
  'nausea': 'غثيان / قيء',
  'arm_radiation': 'ألم ينتشر إلى الذراع أو الكتف أو اليد اليسرى',
  'tingling': 'تنميل أو خدر في الأطراف',
  'tremor': 'رجفة / ارتعاش',
  'cold_extremities': 'برودة في الأطراف',
  'other': 'عرض آخر',
};

// ─── Symptom icons (for UI display) ──────────────────────────────────────────
const Map<String, String> symptomIcons = {
  'palpitations': '💓',
  'irregular': '💔',
  'chest_pain': '🫀',
  'heart_pain': '❤️‍🩹',
  'stabs': '⚡',
  'dyspnea': '🌬️',
  'dizziness': '😵‍💫',
  'fainting': '🫠',
  'fatigue': '😮‍💨',
  'sweating': '💧',
  'nausea': '🤢',
  'arm_radiation': '💪',
  'tingling': '🖐️',
  'tremor': '🫨',
  'cold_extremities': '🥶',
  'other': '➕',
};

// ─── History Stage Questions ─────────────────────────────────────────────────
final List<AssessmentQuestion> historyQuestions = [
  const AssessmentQuestion(
    field: 'history.known_cardiac',
    question: 'هل سبق تشخيصك بمرض في القلب؟ (يمكنك اختيار أكثر من إجابة)',
    type: QuestionType.multiChoice,
    hasNoneOption: true,
    options: [
      QuestionOption(label: 'لا يوجد تشخيص سابق', value: 'none'),
      QuestionOption(label: 'ارتخاء في الصمام الميترالي', value: 'mvp'),
      QuestionOption(label: 'ثقب في القلب / عيب خلقي', value: 'hole_congenital'),
      QuestionOption(label: 'تضخم في القلب', value: 'enlarged'),
      QuestionOption(label: 'عدم انتظام في ضربات القلب / خوارج انقباض', value: 'arrhythmia'),
      QuestionOption(label: 'جلطة أو ذبحة صدرية أو سكتة سابقة', value: 'prior_mi_stroke'),
      QuestionOption(label: 'قسطرة / دعامة / عملية قلب', value: 'catheter_stent'),
      QuestionOption(label: 'تشخيص آخر', value: 'other'),
    ],
  ),
  const AssessmentQuestion(
    field: 'history.known_cardiac_other',
    question: 'ما هو التشخيص الآخر؟',
    type: QuestionType.text,
    dependsOn: DependsOn(
      field: 'history.known_cardiac',
      containsAny: ['other'],
    ),
  ),
  const AssessmentQuestion(
    field: 'history.prior_workup',
    question: 'هل قمت سابقاً بأي من الفحوصات التالية للقلب؟ (يمكنك اختيار أكثر من إجابة)',
    type: QuestionType.multiChoice,
    hasNoneOption: true,
    options: [
      QuestionOption(label: 'لا شيء', value: 'none'),
      QuestionOption(label: 'رسم قلب (ECG)', value: 'ecg'),
      QuestionOption(label: 'أشعة تلفزيونية على القلب (إيكو)', value: 'echo'),
      QuestionOption(label: 'هولتر (رسم قلب لمدة 24 ساعة)', value: 'holter'),
      QuestionOption(label: 'رسم قلب بالمجهود', value: 'stress'),
      QuestionOption(label: 'قسطرة تشخيصية', value: 'cath'),
    ],
  ),
  const AssessmentQuestion(
    field: 'history.chronic_conditions',
    question: 'هل تعاني من أي من الحالات التالية؟ (يمكنك اختيار أكثر من إجابة)',
    type: QuestionType.multiChoice,
    hasNoneOption: true,
    options: [
      QuestionOption(label: 'لا شيء', value: 'none'),
      QuestionOption(label: 'ارتفاع ضغط الدم', value: 'htn'),
      QuestionOption(label: 'انخفاض ضغط الدم', value: 'low_bp'),
      QuestionOption(label: 'السكري', value: 'dm'),
      QuestionOption(label: 'ارتفاع الكوليسترول', value: 'chol'),
      QuestionOption(label: 'اضطراب في الغدة الدرقية', value: 'thyroid'),
      QuestionOption(label: 'فقر دم / أنيميا', value: 'anemia'),
      QuestionOption(label: 'القولون العصبي', value: 'ibs'),
      QuestionOption(label: 'ارتجاع / حموضة / جرثومة المعدة', value: 'reflux'),
    ],
  ),
  const AssessmentQuestion(
    field: 'history.medications',
    question: 'ما الأدوية التي تتناولها حالياً بانتظام؟ (اذكر الاسم والجرعة إن أمكن، أو اكتب "لا شيء")',
    type: QuestionType.text,
  ),
  const AssessmentQuestion(
    field: 'history.med_adherence',
    question: 'هل توقفت عن تناول أي من أدويتك مؤخراً؟',
    type: QuestionType.choice,
    options: [
      QuestionOption(label: 'لا، ملتزم بالدواء', value: 'compliant'),
      QuestionOption(label: 'نعم، توقفت منذ أيام أو أسابيع', value: 'recently_stopped'),
      QuestionOption(label: 'أتناول جرعات غير منتظمة', value: 'irregular'),
    ],
    dependsOn: DependsOn(
      field: 'history.medications',
      notTextIn: ['لا شيء', 'لا', 'none', 'لا يوجد'],
    ),
  ),
  const AssessmentQuestion(
    field: 'history.family_history',
    question: 'هل يعاني أحد الأقارب من الدرجة الأولى من مرض في القلب قبل سن 55؟',
    type: QuestionType.choice,
    options: [
      QuestionOption(label: 'نعم', value: 'yes'),
      QuestionOption(label: 'لا', value: 'no'),
      QuestionOption(label: 'لا أعرف', value: 'unknown'),
    ],
  ),
  const AssessmentQuestion(
    field: 'history.lifestyle',
    question: 'هل ينطبق عليك أي من التالي؟ (يمكنك اختيار أكثر من إجابة)',
    type: QuestionType.multiChoice,
    hasNoneOption: true,
    options: [
      QuestionOption(label: 'لا شيء', value: 'none'),
      QuestionOption(label: 'أدخن حالياً', value: 'smoker'),
      QuestionOption(label: 'مدخن سابق وتركت', value: 'ex_smoker'),
      QuestionOption(label: 'أتناول كمية كبيرة من القهوة أو الشاي (أكثر من 3 أكواب يومياً)', value: 'heavy_caffeine'),
      QuestionOption(label: 'أمارس الرياضة بانتظام', value: 'gym'),
      QuestionOption(label: 'أتناول منشطات أو هرمونات', value: 'supplements'),
    ],
  ),
];

// ─── Symptom Selection Question ──────────────────────────────────────────────
final AssessmentQuestion symptomSelectionQuestion = AssessmentQuestion(
  field: 'symptom_selection.chosen',
  question: 'ما الأعراض التي تشعر بها؟ (اختر كل ما ينطبق عليك)',
  type: QuestionType.multiChoice,
  options: symptomLabels.entries
      .map((e) => QuestionOption(label: e.value, value: e.key))
      .toList(),
);

// ─── Common Symptom Questions (asked for every symptom) ──────────────────────
List<AssessmentQuestion> buildCommonQuestions(String code, String label) {
  return [
    AssessmentQuestion(
      field: 'symptom_detail.$code.severity',
      question: 'ما شدة [$label] عندما تحدث؟',
      type: QuestionType.choice,
      options: const [
        QuestionOption(label: 'بسيطة / خفيفة', value: 'mild'),
        QuestionOption(label: 'متوسطة / مزعجة', value: 'moderate'),
        QuestionOption(label: 'شديدة / قوية', value: 'severe'),
        QuestionOption(label: 'لا أحتمل', value: 'unbearable'),
      ],
    ),
    AssessmentQuestion(
      field: 'symptom_detail.$code.duration_general',
      question: 'منذ متى وأنت تعاني من [$label]؟',
      type: QuestionType.choice,
      options: const [
        QuestionOption(label: 'بدأت اليوم', value: 'today'),
        QuestionOption(label: 'منذ أيام', value: 'days'),
        QuestionOption(label: 'منذ أسابيع', value: 'weeks'),
        QuestionOption(label: 'منذ شهور', value: 'months'),
        QuestionOption(label: 'منذ سنوات', value: 'years'),
        QuestionOption(label: 'منذ الطفولة', value: 'since_childhood'),
      ],
    ),
    AssessmentQuestion(
      field: 'symptom_detail.$code.pattern',
      question: 'كيف يأتي [$label]؟',
      type: QuestionType.choice,
      options: const [
        QuestionOption(label: 'مستمر طوال الوقت / موجود الآن', value: 'continuous'),
        QuestionOption(label: 'نوبات تأتي وتذهب', value: 'episodic'),
        QuestionOption(label: 'نوبة واحدة فقط حتى الآن', value: 'single'),
      ],
    ),
    AssessmentQuestion(
      field: 'symptom_detail.$code.episode_duration',
      question: 'كم تستمر نوبة [$label] عادةً؟',
      type: QuestionType.choice,
      options: const [
        QuestionOption(label: 'ثوانٍ', value: 'seconds'),
        QuestionOption(label: 'دقائق قليلة (< 5 دقائق)', value: 'minutes_short'),
        QuestionOption(label: 'من 5 إلى 30 دقيقة', value: 'minutes_long'),
        QuestionOption(label: 'ساعات', value: 'hours'),
        QuestionOption(label: 'مستمر لا يزول', value: 'continuous'),
      ],
      dependsOn: DependsOn(
        field: 'symptom_detail.$code.pattern',
        equals: 'episodic',
      ),
    ),
    AssessmentQuestion(
      field: 'symptom_detail.$code.triggers',
      question: 'متى يحدث [$label] عادةً؟ (اختر كل ما ينطبق)',
      type: QuestionType.multiChoice,
      options: const [
        QuestionOption(label: 'فجأة بدون سبب واضح', value: 'sudden'),
        QuestionOption(label: 'في الليل', value: 'night'),
        QuestionOption(label: 'أثناء النوم (يوقظني)', value: 'sleep'),
        QuestionOption(label: 'عند الاستيقاظ', value: 'waking'),
        QuestionOption(label: 'عند المجهود / الرياضة / الدرج', value: 'exertion'),
        QuestionOption(label: 'عند الراحة', value: 'rest'),
        QuestionOption(label: 'بعد الأكل', value: 'after_meals'),
        QuestionOption(label: 'عند التوتر أو الغضب', value: 'emotional'),
        QuestionOption(label: 'بعد القهوة / الشاي', value: 'after_caffeine'),
        QuestionOption(label: 'بعد التدخين', value: 'after_smoking'),
        QuestionOption(label: 'مع ملامسة الماء البارد', value: 'cold_water'),
        QuestionOption(label: 'مع الدورة الشهرية', value: 'menstruation'),
      ],
    ),
    AssessmentQuestion(
      field: 'symptom_detail.$code.relieving_factors',
      question: 'ما الذي يخفف [$label]؟ (اختر كل ما ينطبق)',
      type: QuestionType.multiChoice,
      options: const [
        QuestionOption(label: 'الراحة', value: 'rest'),
        QuestionOption(label: 'الدواء', value: 'medication'),
        QuestionOption(label: 'تغيير الوضعية', value: 'position_change'),
        QuestionOption(label: 'التنفس العميق', value: 'deep_breathing'),
        QuestionOption(label: 'لا شيء يخففه', value: 'nothing'),
        QuestionOption(label: 'يزول من تلقاء نفسه', value: 'self_resolves'),
      ],
    ),
  ];
}

// ─── Extra Questions per Symptom ─────────────────────────────────────────────
List<AssessmentQuestion> getExtraQuestions(String code) {
  switch (code) {
    case 'chest_pain':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.radiation',
          question: 'هل ينتشر ألم الصدر إلى مناطق أخرى؟ (اختر كل ما ينطبق)',
          type: QuestionType.multiChoice,
          options: const [
            QuestionOption(label: 'لا ينتشر', value: 'no_radiation'),
            QuestionOption(label: 'الذراع / الكتف / اليد اليسرى', value: 'left_arm'),
            QuestionOption(label: 'الذراع / الكتف / اليد اليمنى', value: 'right_arm'),
            QuestionOption(label: 'الظهر / بين الكتفين', value: 'back'),
            QuestionOption(label: 'الرقبة', value: 'neck'),
            QuestionOption(label: 'الفك أو الأسنان', value: 'jaw'),
            QuestionOption(label: 'أعلى البطن', value: 'upper_abdomen'),
          ],
        ),
        AssessmentQuestion(
          field: 'symptom_detail.$code.exertional',
          question: 'هل يزداد ألم الصدر مع المجهود ويخف مع الراحة؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'نعم', value: 'yes'),
            QuestionOption(label: 'لا', value: 'no'),
            QuestionOption(label: 'لست متأكداً', value: 'not_sure'),
          ],
        ),
        AssessmentQuestion(
          field: 'symptom_detail.$code.quality',
          question: 'كيف تصف طبيعة ألم الصدر؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'ضغط / ثقل', value: 'pressure'),
            QuestionOption(label: 'حرقة / حموضة', value: 'burning'),
            QuestionOption(label: 'طعنة / وخز حاد', value: 'stabbing'),
            QuestionOption(label: 'شد / تشنج', value: 'tightness'),
            QuestionOption(label: 'إحساس غريب يصعب وصفه', value: 'vague'),
          ],
        ),
      ];
    case 'heart_pain':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.radiation',
          question: 'هل ينتشر ألم منطقة القلب إلى مناطق أخرى؟ (اختر كل ما ينطبق)',
          type: QuestionType.multiChoice,
          options: const [
            QuestionOption(label: 'لا ينتشر', value: 'no_radiation'),
            QuestionOption(label: 'الذراع / الكتف / اليد اليسرى', value: 'left_arm'),
            QuestionOption(label: 'الرقبة', value: 'neck'),
            QuestionOption(label: 'الفك', value: 'jaw'),
            QuestionOption(label: 'الظهر', value: 'back'),
          ],
        ),
        AssessmentQuestion(
          field: 'symptom_detail.$code.exertional',
          question: 'هل يزداد ألم منطقة القلب مع المجهود ويخف مع الراحة؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'نعم', value: 'yes'),
            QuestionOption(label: 'لا', value: 'no'),
            QuestionOption(label: 'لست متأكداً', value: 'not_sure'),
          ],
        ),
      ];
    case 'stabs':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.location',
          question: 'أين تقع النغزات / الوخز بالضبط؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'منطقة القلب (اليسار)', value: 'left_precordial'),
            QuestionOption(label: 'منتصف الصدر', value: 'central'),
            QuestionOption(label: 'اليمين', value: 'right'),
            QuestionOption(label: 'عشوائية تتنقل', value: 'moving'),
          ],
        ),
      ];
    case 'palpitations':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.rate_feel',
          question: 'كيف تشعر بضربات القلب أثناء الخفقان؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'سريعة جداً ومنتظمة', value: 'fast_regular'),
            QuestionOption(label: 'سريعة وغير منتظمة', value: 'fast_irregular'),
            QuestionOption(label: 'قوية وأشعر بها في صدري', value: 'forceful'),
            QuestionOption(label: 'أشعر بها في رقبتي', value: 'neck_pounding'),
          ],
        ),
      ];
    case 'irregular':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.skip_or_extra',
          question: 'ما أقرب وصف لما تشعر به؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'إحساس بتوقف لحظي ثم عودة', value: 'pause_then_thump'),
            QuestionOption(label: 'ضربة إضافية خارج النظام', value: 'extra_beat'),
            QuestionOption(label: 'اضطراب كامل في الإيقاع', value: 'full_irregular'),
            QuestionOption(label: 'تسارع مفاجئ ثم عودة طبيعية', value: 'svt_like'),
          ],
        ),
      ];
    case 'dyspnea':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.orthopnea',
          question: 'هل يزداد ضيق التنفس عند الاستلقاء؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'نعم، أحتاج وسائد إضافية', value: 'yes_orthopnea'),
            QuestionOption(label: 'لا', value: 'no'),
            QuestionOption(label: 'لست متأكداً', value: 'not_sure'),
          ],
        ),
        AssessmentQuestion(
          field: 'symptom_detail.$code.exertion_level',
          question: 'ما مستوى الجهد الذي يسبب ضيق التنفس؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'عند المشي السريع / صعود الدرج', value: 'moderate_exertion'),
            QuestionOption(label: 'عند أدنى مجهود (المشي البطيء)', value: 'minimal_exertion'),
            QuestionOption(label: 'عند الراحة التامة', value: 'at_rest'),
            QuestionOption(label: 'لا يرتبط بالمجهود', value: 'unrelated'),
          ],
        ),
      ];
    case 'dizziness':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.type',
          question: 'كيف تصف الدوخة؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'إحساس بالدوران (كأن الأرض تدور)', value: 'vertigo'),
            QuestionOption(label: 'ضبابية / عدم وضوح', value: 'lightheaded'),
            QuestionOption(label: 'إحساس بالإغماء الوشيك', value: 'presyncope'),
            QuestionOption(label: 'عدم اتزان عند المشي', value: 'imbalance'),
          ],
        ),
      ];
    case 'fainting':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.full_loss',
          question: 'هل فقدت الوعي تماماً أم كاد فقط؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'فقدت الوعي تماماً', value: 'complete_loss'),
            QuestionOption(label: 'كاد يحدث / اسودّ أمامي', value: 'near_syncope'),
          ],
        ),
        AssessmentQuestion(
          field: 'symptom_detail.$code.recovery_time',
          question: 'كم استغرق التعافي؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'ثوانٍ (< 1 دقيقة)', value: 'seconds'),
            QuestionOption(label: 'دقيقة أو أكثر', value: 'minutes'),
            QuestionOption(label: 'استدعى التدخل', value: 'required_intervention'),
          ],
        ),
      ];
    case 'arm_radiation':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.side',
          question: 'الانتشار في أي جانب؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'اليسار فقط', value: 'left_only'),
            QuestionOption(label: 'اليمين فقط', value: 'right_only'),
            QuestionOption(label: 'الجانبين', value: 'both'),
          ],
        ),
      ];
    case 'fatigue':
      return [
        AssessmentQuestion(
          field: 'symptom_detail.$code.exertional_change',
          question: 'هل يزداد الإرهاق مع أي مجهود؟',
          type: QuestionType.choice,
          options: const [
            QuestionOption(label: 'نعم بشكل واضح', value: 'yes'),
            QuestionOption(label: 'قليلاً', value: 'slightly'),
            QuestionOption(label: 'لا', value: 'no'),
          ],
        ),
      ];
    default:
      return [];
  }
}

/// Build ALL questions for a given symptom code (common + extras).
List<AssessmentQuestion> buildSymptomQuestions(String code, String label) {
  return [
    ...buildCommonQuestions(code, label),
    ...getExtraQuestions(code),
  ];
}

// ─── Red Flag Questions ──────────────────────────────────────────────────────
List<AssessmentQuestion> buildRedFlagQuestions(List<String> chosenSymptoms) {
  final questions = <AssessmentQuestion>[];

  // Only ask exertional chest if chest_pain and heart_pain are NOT selected
  if (!chosenSymptoms.contains('chest_pain') &&
      !chosenSymptoms.contains('heart_pain')) {
    questions.add(const AssessmentQuestion(
      field: 'red_flags.exertional_chest',
      question: 'هل يوجد ألم في الصدر يزداد مع المجهود ويخف مع الراحة؟',
      type: QuestionType.choice,
      options: [
        QuestionOption(label: 'نعم', value: 'yes'),
        QuestionOption(label: 'لا', value: 'no'),
        QuestionOption(label: 'لست متأكداً', value: 'not_sure'),
      ],
    ));
  }

  questions.add(const AssessmentQuestion(
    field: 'red_flags.syncope_exertion',
    question: 'هل سبق أن أُغمي عليك أثناء الرياضة أو المجهود الشديد؟',
    type: QuestionType.choice,
    options: [
      QuestionOption(label: 'نعم', value: 'yes'),
      QuestionOption(label: 'لا', value: 'no'),
    ],
  ));

  return questions;
}

// ─── Free Text Question ──────────────────────────────────────────────────────
const AssessmentQuestion freeTextQuestion = AssessmentQuestion(
  field: 'free_text.additional',
  question: 'هل هناك أي شيء آخر تود إضافته عن حالتك؟ (إذا لا، اكتب "لا")',
  type: QuestionType.text,
);
