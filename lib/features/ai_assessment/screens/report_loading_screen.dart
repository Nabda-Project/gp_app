import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../../../services/storage_service.dart';
import '../data/ai_assessment_api.dart';
import '../widgets/assessment_theme.dart';
import 'report_result_screen.dart';

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
      // TODO: Remove debug log before production
      log(
        'AI_ASSESSMENT_ERROR — patientId is null, user: ${user?.email}',
        name: 'AI_ASSESSMENT_DEBUG',
      );
      setState(() => _errorMessage = 'تعذّر تحديد هوية المريض. يرجى تسجيل الدخول مجدداً.');
      return;
    }

    // TODO: Remove debug log before production
    log(
      'AI_ASSESSMENT_SUBMIT — patientId: $patientId, endpoint: /ai/consult/$patientId',
      name: 'AI_ASSESSMENT_DEBUG',
    );

    try {
      final result = await AiAssessmentApiService.submitAssessment(
        patientId: patientId,
        assessmentData: widget.submissionJson,
      );

      // TODO: Remove debug log before production
      log(
        'AI_ASSESSMENT_SUCCESS — id: ${result.id}, patientId: ${result.patientId}, '
        'aiReport.length: ${result.aiReport.length}',
        name: 'AI_ASSESSMENT_DEBUG',
      );

      if (!mounted) return;

      // Navigate to report result screen with the original submission JSON
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReportResultScreen(
            report: result,
            submissionJson: widget.submissionJson,
          ),
        ),
      );
    } catch (e) {
      // TODO: Remove debug log before production
      log(
        'AI_ASSESSMENT_ERROR — $e',
        name: 'AI_ASSESSMENT_DEBUG',
      );
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
