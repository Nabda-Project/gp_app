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

  @override
  void initState() {
    super.initState();
    _future = AiAssessmentApiService.getMyReports();
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
              color: AssessmentColors.primary.withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.2),
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
            onTap: () => setState(() {
              _future = AiAssessmentApiService.getMyReports();
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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
    // Get a preview of the report text (first 100 chars)
    final preview = r.aiReport.length > 120
        ? '${r.aiReport.substring(0, 120)}...'
        : r.aiReport;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportResultScreen(report: r),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AssessmentShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top colored bar with date
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                gradient: AssessmentColors.cardGradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'التقرير ${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo'),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Report preview
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview,
                    style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Cairo',
                        color: AssessmentColors.textSecondary,
                        height: 1.6),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AssessmentColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.open_in_new_rounded,
                                size: 14, color: AssessmentColors.primary),
                            SizedBox(width: 4),
                            Text('عرض التقرير',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Cairo',
                                    color: AssessmentColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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
            const Text(
              'لا توجد تقارير سابقة',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: AssessmentColors.textPrimary),
            ),
            const SizedBox(height: 12),
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
            const Text(
              'تعذّر تحميل التقارير',
              style: TextStyle(
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
              onPressed: () => setState(
                  () => _future = AiAssessmentApiService.getMyReports()),
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
