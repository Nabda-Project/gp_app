import 'package:flutter/material.dart';
import '../data/ai_assessment_api.dart';
import '../models/assessment_models.dart';
import '../widgets/assessment_theme.dart';
import 'report_result_screen.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  late Future<List<AiConsultResponse>> _future;
  int? _patientId;
  String? _patientName;
  bool _isDoctorView = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _patientId = args?['patientId'] as int?;
      _patientName = args?['patientName'] as String?;
      _isDoctorView = args?['isDoctorView'] as bool? ?? false;
      
      _fetchData();
      _initialized = true;
    }
  }

  void _fetchData() {
    setState(() {
      if (_isDoctorView && _patientId != null) {
        _future = AiAssessmentApiService.getPatientReportsForDoctor(_patientId!);
      } else {
        _future = AiAssessmentApiService.getMyReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AssessmentColors.background,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: FutureBuilder<List<AiConsultResponse>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AssessmentColors.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString());
                  }
                  final reports = snapshot.data ?? [];
                  if (reports.isEmpty) return _buildEmpty();
                  return _buildList(reports);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: AssessmentColors.headerGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
              color: AssessmentColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('التقارير السابقة',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo')),
              Text('سجل تقارير القلب',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFamily: 'Cairo')),
            ],
          ),
          const Spacer(),
          // Refresh button
          GestureDetector(
            onTap: _fetchData,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AiConsultResponse> reports) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final r = reports[index];
        return _buildReportCard(context, r, index);
      },
    );
  }

  Widget _buildReportCard(BuildContext context, AiConsultResponse r, int index) {
    final dateStr = _formatDate(r.createdAt);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportResultScreen(
            report: r,
            patientNameOverride: _patientName ?? r.patientName,
            isDoctorView: _isDoctorView,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AssessmentShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AssessmentColors.primarySurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.description_rounded,
                  color: AssessmentColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تقرير رقم ${index + 1}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: AssessmentColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AssessmentColors.textMuted, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'تاريخ التقرير: $dateStr',
                        style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Cairo',
                            color: AssessmentColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AssessmentColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'مكتمل',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: AssessmentColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AssessmentColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.article_outlined,
                  size: 60, color: AssessmentColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              _isDoctorView ? 'لا توجد تقارير لهذا المريض حتى الآن' : 'لا توجد تقارير سابقة',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: AssessmentColors.textPrimary),
            ),
            const SizedBox(height: 12),
            if (!_isDoctorView) ...[
              const Text(
                'أجرِ تقييمك الأول للحصول على تقرير طبي مفصّل',
                style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: AssessmentColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/assessment_welcome'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('ابدأ تقييمًا',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AssessmentColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AssessmentColors.textMuted),
            const SizedBox(height: 20),
            Text(
              _isDoctorView ? 'تعذر تحميل تقارير المريض' : 'تعذّر تحميل التقارير',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: AssessmentColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(error,
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Cairo',
                    color: AssessmentColors.textMuted),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AssessmentColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
