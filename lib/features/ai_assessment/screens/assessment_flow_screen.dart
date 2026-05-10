import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../models/assessment_models.dart';
import '../data/cardiac_questions.dart';
import '../widgets/assessment_theme.dart';
import '../widgets/assessment_progress_header.dart';
import '../widgets/question_card.dart';
import '../widgets/choice_option_card.dart';
import '../widgets/assessment_next_button.dart';
import '../widgets/medical_gradient_background.dart';

/// Stages of the assessment flow
enum AssessmentStage { history, symptomSelection, symptomDetail, redFlags, freeText }

/// Holds all collected answers
class AssessmentState {
  Map<String, dynamic> data = {};

  void set(String fieldPath, dynamic value) {
    final parts = fieldPath.split('.');
    Map<String, dynamic> current = data;
    for (int i = 0; i < parts.length - 1; i++) {
      current = current.putIfAbsent(parts[i], () => <String, dynamic>{})
          as Map<String, dynamic>;
    }
    current[parts.last] = value;
  }

  dynamic get(String fieldPath) {
    final parts = fieldPath.split('.');
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

  List<String> get chosenSymptoms {
    final chosen = get('symptom_selection.chosen');
    if (chosen is List) return chosen.cast<String>();
    return [];
  }

  /// Build the final JSON for submission.
  /// Demographics are NOT included — the backend fetches them from the DB.
  Map<String, dynamic> buildSubmissionJson() {
    final chosen = chosenSymptoms;
    final symptomDetail = <String, dynamic>{};
    final otherSymptoms = <Map<String, dynamic>>[];

    // Collect codes for chosen list (regular + other_N codes)
    final chosenCodes = <String>[];

    for (final code in chosen) {
      if (code == 'other') {
        final count = (get('other_count') as num?)?.toInt() ?? 0;
        for (int i = 0; i < count; i++) {
          final label = get('other_label_$i') as String? ?? '';
          otherSymptoms.add({'code': 'other_$i', 'label': label});
          chosenCodes.add('other_$i');
          final detail = get('symptom_detail.other_$i');
          if (detail != null) symptomDetail['other_$i'] = detail;
        }
      } else {
        chosenCodes.add(code);
        final detail = get('symptom_detail.$code');
        if (detail != null) symptomDetail[code] = detail;
      }
    }

    final json = {
      'history': data['history'] ?? <String, dynamic>{},
      'symptom_selection': {'chosen': chosenCodes},
      'symptom_detail': symptomDetail,
      'other_symptoms': otherSymptoms,
      'red_flags': data['red_flags'] ?? <String, dynamic>{},
      'free_text': data['free_text'] ?? <String, dynamic>{},
    };

    // Debug logging — verify final JSON structure
    log(
      const JsonEncoder.withIndent('  ').convert(json),
      name: 'AI_ASSESSMENT_FINAL_JSON',
    );

    return json;
  }
}

class AssessmentFlowScreen extends StatefulWidget {
  const AssessmentFlowScreen({super.key});

  @override
  State<AssessmentFlowScreen> createState() => _AssessmentFlowScreenState();
}

class _AssessmentFlowScreenState extends State<AssessmentFlowScreen>
    with SingleTickerProviderStateMixin {
  final AssessmentState _state = AssessmentState();

  AssessmentStage _stage = AssessmentStage.history;
  int _historyIndex = 0;
  int _currentSymptomIndex = 0;
  int _symptomQuestionIndex = 0;
  bool _inOtherCountStep = false;
  bool _inOtherLabelStep = false;
  int _otherLabelIndex = 0;

  late List<AssessmentQuestion> _currentSymptomQuestions;
  late List<String> _regularSymptoms; // non-other chosen symptoms
  late int _otherCount;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Track currently active question for nav
  AssessmentQuestion? get _currentQuestion {
    switch (_stage) {
      case AssessmentStage.history:
        return _visibleHistoryQuestions.isNotEmpty &&
                _historyIndex < _visibleHistoryQuestions.length
            ? _visibleHistoryQuestions[_historyIndex]
            : null;
      case AssessmentStage.symptomSelection:
        return symptomSelectionQuestion;
      case AssessmentStage.symptomDetail:
        if (_inOtherCountStep || _inOtherLabelStep) return null;
        if (_currentSymptomIndex < _regularSymptoms.length &&
            _symptomQuestionIndex < _currentSymptomQuestions.length) {
          return _currentSymptomQuestions[_symptomQuestionIndex];
        }
        return null;
      case AssessmentStage.redFlags:
        final rfs = buildRedFlagQuestions(_state.chosenSymptoms);
        if (_historyIndex < rfs.length) return rfs[_historyIndex];
        return null;
      case AssessmentStage.freeText:
        return freeTextQuestion;
    }
  }

  List<AssessmentQuestion> get _visibleHistoryQuestions {
    return historyQuestions.where((q) {
      if (q.dependsOn == null) return true;
      return q.dependsOn!.evaluate(_state.data);
    }).toList();
  }

  int get _totalSteps => 5;
  int get _currentStep {
    switch (_stage) {
      case AssessmentStage.history:
        return 1;
      case AssessmentStage.symptomSelection:
        return 2;
      case AssessmentStage.symptomDetail:
        return 3;
      case AssessmentStage.redFlags:
        return 4;
      case AssessmentStage.freeText:
        return 5;
    }
  }

  String get _stageTitle {
    switch (_stage) {
      case AssessmentStage.history:
        return 'التاريخ المرضي';
      case AssessmentStage.symptomSelection:
        return 'الأعراض';
      case AssessmentStage.symptomDetail:
        if (_inOtherCountStep) return 'أعراض أخرى';
        if (_inOtherLabelStep) return 'عرض إضافي';
        if (_regularSymptoms.isNotEmpty &&
            _currentSymptomIndex < _regularSymptoms.length) {
          final code = _regularSymptoms[_currentSymptomIndex];
          return 'العرض ${_currentSymptomIndex + 1} من ${_regularSymptoms.length}: ${symptomLabels[code] ?? code}';
        }
        return 'تفاصيل الأعراض';
      case AssessmentStage.redFlags:
        return 'أسئلة مهمة';
      case AssessmentStage.freeText:
        return 'ملاحظات إضافية';
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _regularSymptoms = [];
    _otherCount = 0;
    _currentSymptomQuestions = [];
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateNext() {
    _animController.reset();
    _animController.forward();
  }

  bool _isCurrentAnswered() {
    final q = _currentQuestion;

    if (_inOtherCountStep) {
      final v = _state.get('other_count');
      return v != null && (v as num) >= 1;
    }
    if (_inOtherLabelStep) {
      final v = _state.get('other_label_$_otherLabelIndex') as String?;
      return v != null && v.trim().isNotEmpty;
    }
    if (q == null) return true;

    final val = _state.get(q.field);
    if (val == null) return false;
    if (val is List) return val.isNotEmpty;
    if (val is String) return val.trim().isNotEmpty;
    return true;
  }

  void _goNext() {
    if (!_isCurrentAnswered()) return;
    setState(() {
      switch (_stage) {
        case AssessmentStage.history:
          _advanceHistory();
          break;
        case AssessmentStage.symptomSelection:
          _initSymptomDetail();
          break;
        case AssessmentStage.symptomDetail:
          _advanceSymptomDetail();
          break;
        case AssessmentStage.redFlags:
          _advanceRedFlags();
          break;
        case AssessmentStage.freeText:
          _goToReview();
          break;
      }
      _animateNext();
    });
  }

  void _goBack() {
    setState(() {
      switch (_stage) {
        case AssessmentStage.history:
          if (_historyIndex > 0) {
            _historyIndex--;
          } else {
            Navigator.pop(context);
          }
          break;
        case AssessmentStage.symptomSelection:
          _stage = AssessmentStage.history;
          _historyIndex = _visibleHistoryQuestions.length - 1;
          break;
        case AssessmentStage.symptomDetail:
          _backSymptomDetail();
          break;
        case AssessmentStage.redFlags:
          if (_historyIndex > 0) {
            _historyIndex--;
          } else {
            _stage = AssessmentStage.symptomDetail;
            _backToLastSymptomQuestion();
          }
          break;
        case AssessmentStage.freeText:
          _stage = AssessmentStage.redFlags;
          final rfs = buildRedFlagQuestions(_state.chosenSymptoms);
          _historyIndex = rfs.length - 1;
          break;
      }
      _animateNext();
    });
  }

  void _advanceHistory() {
    final visible = _visibleHistoryQuestions;
    if (_historyIndex < visible.length - 1) {
      _historyIndex++;
    } else {
      _stage = AssessmentStage.symptomSelection;
      _historyIndex = 0;
    }
  }

  void _initSymptomDetail() {
    final chosen = _state.chosenSymptoms;
    _regularSymptoms = chosen.where((c) => c != 'other').toList();
    final hasOther = chosen.contains('other');

    if (_regularSymptoms.isNotEmpty) {
      _stage = AssessmentStage.symptomDetail;
      _currentSymptomIndex = 0;
      _symptomQuestionIndex = 0;
      _inOtherCountStep = false;
      _inOtherLabelStep = false;
      _loadCurrentSymptomQuestions();
    } else if (hasOther) {
      _stage = AssessmentStage.symptomDetail;
      _inOtherCountStep = true;
    } else {
      _stage = AssessmentStage.redFlags;
      _historyIndex = 0;
    }
  }

  void _loadCurrentSymptomQuestions() {
    if (_currentSymptomIndex < _regularSymptoms.length) {
      final code = _regularSymptoms[_currentSymptomIndex];
      final label = symptomLabels[code] ?? code;
      _currentSymptomQuestions = buildSymptomQuestions(code, label);
      // filter by dependsOn
      _skipToNextVisibleQuestion();
    }
  }

  void _skipToNextVisibleQuestion() {
    while (_symptomQuestionIndex < _currentSymptomQuestions.length) {
      final q = _currentSymptomQuestions[_symptomQuestionIndex];
      if (q.dependsOn == null || q.dependsOn!.evaluate(_state.data)) break;
      _symptomQuestionIndex++;
    }
  }

  void _advanceSymptomDetail() {
    if (_inOtherCountStep) {
      _otherCount = (_state.get('other_count') as num).toInt();
      _inOtherCountStep = false;
      _inOtherLabelStep = true;
      _otherLabelIndex = 0;
      return;
    }
    if (_inOtherLabelStep) {
      if (_otherLabelIndex < _otherCount - 1) {
        _otherLabelIndex++;
      } else {
        // done with other labels - go to common questions for other_0..N
        // For simplicity, treat other symptoms as regular with code other_X
        final otherCodes = List.generate(_otherCount, (i) => 'other_$i');
        _regularSymptoms = [..._regularSymptoms, ...otherCodes];
        _inOtherLabelStep = false;
        _loadCurrentSymptomQuestions();
      }
      return;
    }

    // Advance within current symptom questions
    int next = _symptomQuestionIndex + 1;
    while (next < _currentSymptomQuestions.length) {
      final q = _currentSymptomQuestions[next];
      if (q.dependsOn == null || q.dependsOn!.evaluate(_state.data)) break;
      next++;
    }

    if (next < _currentSymptomQuestions.length) {
      _symptomQuestionIndex = next;
    } else {
      // Move to next symptom
      _currentSymptomIndex++;
      if (_currentSymptomIndex < _regularSymptoms.length) {
        _symptomQuestionIndex = 0;
        _loadCurrentSymptomQuestions();
      } else {
        // Check if other was selected and not yet handled
        if (_state.chosenSymptoms.contains('other') && !_inOtherLabelStep) {
          _inOtherCountStep = true;
        } else {
          _stage = AssessmentStage.redFlags;
          _historyIndex = 0;
        }
      }
    }
  }

  void _backSymptomDetail() {
    if (_inOtherLabelStep) {
      if (_otherLabelIndex > 0) {
        _otherLabelIndex--;
      } else {
        _inOtherLabelStep = false;
        _inOtherCountStep = true;
      }
      return;
    }
    if (_inOtherCountStep) {
      _inOtherCountStep = false;
      if (_regularSymptoms.isNotEmpty) {
        _currentSymptomIndex = _regularSymptoms.length - 1;
        _loadCurrentSymptomQuestions();
        _symptomQuestionIndex = _currentSymptomQuestions.length - 1;
      } else {
        _stage = AssessmentStage.symptomSelection;
      }
      return;
    }

    // Go back within current symptom
    int prev = _symptomQuestionIndex - 1;
    while (prev >= 0) {
      final q = _currentSymptomQuestions[prev];
      if (q.dependsOn == null || q.dependsOn!.evaluate(_state.data)) break;
      prev--;
    }
    if (prev >= 0) {
      _symptomQuestionIndex = prev;
    } else if (_currentSymptomIndex > 0) {
      _currentSymptomIndex--;
      _loadCurrentSymptomQuestions();
      _symptomQuestionIndex = _currentSymptomQuestions.length - 1;
    } else {
      _stage = AssessmentStage.symptomSelection;
    }
  }

  void _backToLastSymptomQuestion() {
    final chosen = _state.chosenSymptoms;
    _regularSymptoms = chosen.where((c) => c != 'other').toList();
    if (_regularSymptoms.isNotEmpty) {
      _currentSymptomIndex = _regularSymptoms.length - 1;
      _loadCurrentSymptomQuestions();
      _symptomQuestionIndex = _currentSymptomQuestions.length - 1;
    }
  }

  void _advanceRedFlags() {
    final rfs = buildRedFlagQuestions(_state.chosenSymptoms);
    if (_historyIndex < rfs.length - 1) {
      _historyIndex++;
    } else {
      _stage = AssessmentStage.freeText;
      _historyIndex = 0;
    }
  }

  void _goToReview() {
    Navigator.pushNamed(
      context,
      '/assessment_review',
      arguments: _state,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AssessmentColors.background,
        body: Column(
          children: [
            AssessmentProgressHeader(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              title: _stageTitle,
              onBack: _goBack,
            ),
            Expanded(
              child: MedicalGradientBackground(
                showDecorations: false,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildBody(),
                  ),
                ),
              ),
            ),
            AssessmentNextButton(
              label: _stage == AssessmentStage.freeText ? 'مراجعة الإجابات' : 'التالي',
              icon: _stage == AssessmentStage.freeText
                  ? Icons.checklist_rounded
                  : null,
              onPressed: _isCurrentAnswered() ? _goNext : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_inOtherCountStep) return _buildOtherCountStep();
    if (_inOtherLabelStep) return _buildOtherLabelStep();

    final q = _currentQuestion;
    if (q == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: QuestionCard(
        question: q.question,
        icon: _iconForStage(),
        child: _buildQuestionInput(q),
      ),
    );
  }

  IconData _iconForStage() {
    switch (_stage) {
      case AssessmentStage.history:
        return Icons.history_edu_rounded;
      case AssessmentStage.symptomSelection:
        return Icons.checklist_rounded;
      case AssessmentStage.symptomDetail:
        return Icons.favorite_border_rounded;
      case AssessmentStage.redFlags:
        return Icons.warning_amber_rounded;
      case AssessmentStage.freeText:
        return Icons.notes_rounded;
    }
  }

  Widget _buildOtherCountStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: QuestionCard(
        question: 'كم عدد الأعراض الإضافية الأخرى التي تريد وصفها؟',
        icon: Icons.add_circle_outline_rounded,
        child: _buildNumberInput('other_count', min: 1, max: 10),
      ),
    );
  }

  Widget _buildOtherLabelStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: QuestionCard(
        question: 'ما هو العرض الإضافي رقم ${_otherLabelIndex + 1}؟ (اكتب وصفاً مختصراً بالعربي)',
        icon: Icons.edit_note_rounded,
        child: _buildTextInput('other_label_$_otherLabelIndex'),
      ),
    );
  }

  Widget _buildQuestionInput(AssessmentQuestion q) {
    switch (q.type) {
      case QuestionType.choice:
        return _buildChoiceInput(q);
      case QuestionType.multiChoice:
        return _buildMultiChoiceInput(q);
      case QuestionType.text:
        return _buildTextInput(q.field);
      case QuestionType.number:
        return _buildNumberInput(q.field, min: q.min, max: q.max);
    }
  }

  Widget _buildChoiceInput(AssessmentQuestion q) {
    final current = _state.get(q.field) as String?;
    return Column(
      children: q.options!.map((opt) {
        return ChoiceOptionCard(
          label: opt.label,
          isSelected: current == opt.value,
          onTap: () {
            setState(() => _state.set(q.field, opt.value));
          },
        );
      }).toList(),
    );
  }

  Widget _buildMultiChoiceInput(AssessmentQuestion q) {
    final current = (_state.get(q.field) as List?)?.cast<String>() ?? [];
    return Column(
      children: q.options!.map((opt) {
        final isSelected = current.contains(opt.value);
        return MultiChoiceOptionCard(
          label: opt.label,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              final updated = List<String>.from(current);
              if (opt.value == 'none') {
                // none clears all
                updated.clear();
                updated.add('none');
              } else if (isSelected) {
                updated.remove(opt.value);
              } else {
                updated.remove('none');
                updated.add(opt.value);
              }
              _state.set(q.field, updated);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTextInput(String field) {
    final controller =
        TextEditingController(text: _state.get(field) as String? ?? '');
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    return TextField(
      controller: controller,
      textDirection: TextDirection.rtl,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'اكتب هنا...',
        hintStyle: const TextStyle(
            color: AssessmentColors.textMuted, fontFamily: 'Cairo'),
        filled: true,
        fillColor: AssessmentColors.primarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AssessmentColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(
          fontFamily: 'Cairo', fontSize: 15, color: AssessmentColors.textPrimary),
      onChanged: (v) => setState(() => _state.set(field, v)),
    );
  }

  Widget _buildNumberInput(String field, {double? min, double? max}) {
    final current = _state.get(field);
    final controller = TextEditingController(
        text: current != null ? current.toString() : '');
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: min != null && max != null
            ? 'أدخل رقمًا بين ${min.toInt()} و ${max.toInt()}'
            : 'أدخل رقمًا',
        hintStyle: const TextStyle(
            color: AssessmentColors.textMuted, fontFamily: 'Cairo'),
        filled: true,
        fillColor: AssessmentColors.primarySurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AssessmentColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(
          fontFamily: 'Cairo', fontSize: 15, color: AssessmentColors.textPrimary),
      onChanged: (v) {
        final n = num.tryParse(v);
        if (n != null) {
          if ((min == null || n >= min) && (max == null || n <= max)) {
            setState(() => _state.set(field, n));
          }
        }
      },
    );
  }
}
