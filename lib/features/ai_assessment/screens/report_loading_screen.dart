import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';
import '../data/ai_assessment_api.dart';
import '../models/assessment_models.dart';
import '../widgets/assessment_theme.dart';

class ReportLoadingScreen extends StatefulWidget {
  final Map<String, dynamic> submissionJson;

  const ReportLoadingScreen({super.key, required this.submissionJson});

  @override
  State<ReportLoadingScreen> createState() => _ReportLoadingScreenState();
}

class _ReportLoadingScreenState extends State<ReportLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Timer _msgTimer;

  int _msgIndex = 0;
  bool _hasSubmitted = false;
  String? _errorMessage;

  static const _messages = [
    'جاري تحليل البيانات...',
    'نراجع التاريخ المرضي...',
    'نفحص عوامل الخطورة...',
    'نحلل الأعراض المذكورة...',
    'نجهز التقرير الطبي...',
    'قد يستغرق هذا بعض الوقت...',
    'الذكاء الاصطناعي يعمل على تقريرك...',
    'نقارب الانتهاء...',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _msgTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
    });

    _submit();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _msgTimer.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_hasSubmitted) return;
    _hasSubmitted = true;

    final user = StorageService.getUser();
    final patientId = user?.backendId;

    if (patientId == null) {
      setState(() => _errorMessage = 'تعذّر تحديد هوية المريض. يرجى تسجيل الدخول مجدداً.');
      return;
    }

    try {
      final result = await AiAssessmentApiService.submitAssessment(
        patientId: patientId,
        assessmentData: widget.submissionJson,
      );

      // Log the merged response from backend
      log(
        'AI_ASSESSMENT_MERGED_FROM_BACKEND — patientId: ${result.patientId}, '
        'demographics: ${result.demographics}',
        name: 'AiAssessmentApi',
      );

      if (!mounted) return;

      // Navigate to success screen showing demographics were merged
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _AssessmentSuccessScreen(mergedResponse: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'عذراً، حدث خطأ في الخادم. يرجى المحاولة لاحقاً.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AssessmentColors.loadingGradient,
          ),
          child: SafeArea(
            child: _errorMessage != null
                ? _buildError()
                : _buildLoading(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        // Animated heart
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Transform.scale(
            scale: 0.9 + 0.1 * _pulseController.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 70,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Rotating indicator
        AnimatedBuilder(
          animation: _rotateController,
          builder: (_, __) => Transform.rotate(
            angle: _rotateController.value * 6.28,
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Rotating messages
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            _messages[_msgIndex],
            key: ValueKey(_msgIndex),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'يرجى عدم إغلاق التطبيق',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.7),
            fontFamily: 'Cairo',
          ),
        ),
        const Spacer(flex: 3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: LinearProgressIndicator(
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 64),
          ),
          const SizedBox(height: 32),
          const Text(
            'تعذّر إنشاء التقرير',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
                fontFamily: 'Cairo',
                height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/patient_dashboard', (route) => false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('الرئيسية',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _hasSubmitted = false;
                    });
                    _submit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AssessmentColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('إعادة المحاولة',
                      style: TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Success screen (assessment received, demographics merged) ────────────────

class _AssessmentSuccessScreen extends StatelessWidget {
  final ChatbotMergedResponse mergedResponse;

  const _AssessmentSuccessScreen({required this.mergedResponse});

  @override
  Widget build(BuildContext context) {
    final demographics = mergedResponse.demographics;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0F5FF), Color(0xFFE8F0FF), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Success icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AssessmentColors.cardGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AssessmentColors.primary.withOpacity(0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'تم إرسال التقييم بنجاح',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: AssessmentColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تم دمج بياناتك الديموغرافية من الملف الشخصي',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Cairo',
                      color: AssessmentColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Demographics card
                  if (demographics.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AssessmentShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  color: AssessmentColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'البيانات الديموغرافية من الملف',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  color: AssessmentColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (demographics['age'] != null)
                            _infoRow('العمر', '${demographics['age']} سنة'),
                          if (demographics['sex'] != null)
                            _infoRow('الجنس',
                                demographics['sex'] == 'male' ? 'ذكر' : 'أنثى'),
                          if (demographics['height_cm'] != null)
                            _infoRow('الطول', '${demographics['height_cm']} سم'),
                          if (demographics['weight_kg'] != null)
                            _infoRow('الوزن', '${demographics['weight_kg']} كجم'),
                        ],
                      ),
                    ),
                  const Spacer(flex: 2),
                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AssessmentColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AssessmentColors.warning.withOpacity(0.8),
                            size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'سيتم إنشاء التقرير الطبي الذكي قريباً',
                            style: TextStyle(
                              fontSize: 12,
                              color: AssessmentColors.textSecondary,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Actions
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/patient_dashboard', (route) => false),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('العودة للرئيسية',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AssessmentColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/assessment_welcome'),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('تقييم جديد',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AssessmentColors.primary,
                        side: const BorderSide(color: AssessmentColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: AssessmentColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Cairo',
                color: AssessmentColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
