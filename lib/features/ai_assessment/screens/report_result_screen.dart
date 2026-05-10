import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/assessment_models.dart';
import '../widgets/assessment_theme.dart';

class ReportResultScreen extends StatelessWidget {
  final AiConsultResponse report;

  const ReportResultScreen({super.key, required this.report});

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaCard(),
                    const SizedBox(height: 16),
                    _buildReportContent(),
                    const SizedBox(height: 16),
                    _buildDisclaimer(),
                    const SizedBox(height: 16),
                    _buildActions(context),
                  ],
                ),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التقرير الطبي',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo')),
                Text('تم إنشاء تقريرك بنجاح',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, fontFamily: 'Cairo')),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                Navigator.popUntil(context, ModalRoute.withName('/patient_dashboard')),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard() {
    final dateStr = _formatDate(report.createdAt);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AssessmentShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AssessmentColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AssessmentColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تاريخ التقرير',
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Cairo',
                      color: AssessmentColors.textMuted)),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: AssessmentColors.textPrimary)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AssessmentColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'مكتمل',
              style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: AssessmentColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    // Try to parse as JSON first
    dynamic parsed;
    try {
      parsed = jsonDecode(report.aiReport);
    } catch (_) {
      parsed = null;
    }

    if (parsed is Map<String, dynamic>) {
      return _buildJsonReport(parsed);
    }
    return _buildTextReport(report.aiReport);
  }

  Widget _buildJsonReport(Map<String, dynamic> json) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: json.entries.map((e) {
        return _reportSectionCard(
          title: _translateKey(e.key),
          content: e.value?.toString() ?? '',
        );
      }).toList(),
    );
  }

  Widget _buildTextReport(String text) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    String? currentSection;
    final currentLines = <String>[];

    void flushSection() {
      if (currentLines.isEmpty) return;
      widgets.add(_reportSectionCard(
        title: currentSection ?? 'التقرير',
        content: currentLines.join('\n'),
      ));
      currentLines.clear();
      currentSection = null;
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Detect markdown headings
      if (trimmed.startsWith('##') || trimmed.startsWith('**')) {
        flushSection();
        currentSection = trimmed.replaceAll(RegExp(r'[#*]'), '').trim();
      } else {
        currentLines.add(trimmed);
      }
    }
    flushSection();

    if (widgets.isEmpty) {
      widgets.add(_reportSectionCard(title: 'نتيجة التقرير', content: text));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _reportSectionCard({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AssessmentShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: AssessmentColors.primarySurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: AssessmentColors.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Cairo',
                  color: AssessmentColors.textPrimary,
                  height: 1.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AssessmentColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AssessmentColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AssessmentColors.warning, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'هذا التقرير استرشادي ولا يُغني عن استشارة الطبيب.',
              style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Cairo',
                  color: AssessmentColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.popUntil(context, ModalRoute.withName('/patient_dashboard')),
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
                Navigator.pushNamed(context, '/report_history'),
            icon: const Icon(Icons.history_rounded),
            label: const Text('تقاريري السابقة',
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
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _translateKey(String key) {
    const map = {
      'summary': 'الملخص',
      'diagnosis': 'التشخيص المحتمل',
      'risk': 'عوامل الخطورة',
      'risk_level': 'مستوى الخطورة',
      'recommendations': 'التوصيات',
      'urgency': 'مستوى الاستعجال',
      'differentials': 'التشخيصات التفاضلية',
      'red_flags': 'علامات التحذير',
      'follow_up': 'متابعة',
    };
    return map[key.toLowerCase()] ?? key;
  }
}
