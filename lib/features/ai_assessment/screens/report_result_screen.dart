// Redesigned AI medical report display screen.
//
// Parses `AiConsultResponse.aiReport` (JSON or plain text) and renders
// it as a professional, Arabic, patient-friendly medical report with:
// - Patient name + date + status header
// - Translated Arabic section cards
// - Empty section / field hiding
// - PDF export via `ReportPdfExporter`
import 'package:flutter/material.dart';
import '../models/assessment_models.dart';
import '../utils/report_formatter.dart';
import '../utils/report_pdf_exporter.dart';
import '../widgets/assessment_theme.dart';
import '../widgets/report_section_card.dart';
import '../../../services/storage_service.dart';

class ReportResultScreen extends StatelessWidget {
  final AiConsultResponse report;
  final String? patientNameOverride;
  final bool isDoctorView;

  const ReportResultScreen({
    super.key, 
    required this.report,
    this.patientNameOverride,
    this.isDoctorView = false,
  });

  // ── Icon map for known sections ────────────────────────────────────────
  static const Map<String, IconData> _sectionIcons = {
    'symptoms': Icons.sick_outlined,
    'old_diagnosis': Icons.medical_information_outlined,
    'medication': Icons.medication_outlined,
    'medications': Icons.medication_outlined,
    'notes': Icons.sticky_note_2_outlined,
    'recommendations': Icons.recommend_outlined,
    'risk_factors': Icons.warning_amber_rounded,
    'summary': Icons.summarize_outlined,
    'diagnosis': Icons.local_hospital_outlined,
    'warnings': Icons.report_problem_outlined,
    'next_steps': Icons.checklist_outlined,
    'risk': Icons.warning_amber_rounded,
    'risk_level': Icons.shield_outlined,
    'urgency': Icons.priority_high_rounded,
    'differentials': Icons.compare_arrows_rounded,
    'red_flags': Icons.flag_outlined,
    'follow_up': Icons.event_note_outlined,
    'history': Icons.history_edu_outlined,
    'lifestyle': Icons.directions_run_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final user = StorageService.getUser();
    final patientName = patientNameOverride ?? (
        (user?.fullName != null && user!.fullName.trim().isNotEmpty)
            ? user.fullName
            : 'المريض'
    );

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
                    _buildPatientInfoCard(patientName),
                    const SizedBox(height: 16),
                    ..._buildReportSections(),
                    const SizedBox(height: 8),
                    _buildDisclaimer(),
                    const SizedBox(height: 20),
                    _buildActions(context, patientName),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

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
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
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
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Cairo')),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (isDoctorView) {
                Navigator.pop(context);
              } else {
                Navigator.popUntil(context, ModalRoute.withName('/patient_dashboard'));
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Patient info card ──────────────────────────────────────────────────

  Widget _buildPatientInfoCard(String patientName) {
    final dateStr = ReportFormatter.formatDateArabic(report.createdAt);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AssessmentShadows.card,
      ),
      child: Column(
        children: [
          // Patient name row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AssessmentColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_rounded,
                    color: AssessmentColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اسم المريض',
                        style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Cairo',
                            color: AssessmentColors.textMuted)),
                    Text(patientName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            color: AssessmentColors.textPrimary)),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AssessmentColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: AssessmentColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'مكتمل',
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: AssessmentColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          Container(
            height: 1,
            color: AssessmentColors.primary.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 12),
          // Date row
          Row(
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
            ],
          ),
        ],
      ),
    );
  }

  // ── Report content ─────────────────────────────────────────────────────

  List<Widget> _buildReportSections() {
    final parsed = ReportFormatter.tryParseJson(report.aiReport);

    if (parsed is Map<String, dynamic>) {
      return _buildJsonSections(parsed);
    }

    // Plain text / markdown fallback
    return _buildTextSections(report.aiReport);
  }

  List<Widget> _buildJsonSections(Map<String, dynamic> json) {
    final widgets = <Widget>[];
    for (final entry in json.entries) {
      // Skip empty sections
      if (ReportFormatter.isEmpty(entry.value)) continue;

      final title = ReportFormatter.translateSection(entry.key);
      final icon = _sectionIcons[entry.key.toLowerCase()];

      widgets.add(
        ReportSectionCard(
          title: title,
          content: entry.value,
          icon: icon,
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(_buildNoContent());
    }

    return widgets;
  }

  List<Widget> _buildTextSections(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return [_buildNoContent()];
    }

    final lines = trimmed.split('\n');
    final sectionWidgets = <Widget>[];
    String? currentTitle;
    final currentLines = <String>[];

    void flushSection() {
      if (currentLines.isEmpty) return;
      sectionWidgets.add(
        ReportSectionCard(
          title: currentTitle ?? 'التقرير',
          content: currentLines.join('\n'),
          icon: Icons.article_outlined,
        ),
      );
      currentLines.clear();
      currentTitle = null;
    }

    for (final line in lines) {
      final l = line.trim();
      if (l.isEmpty) continue;
      // Detect markdown headings
      if (l.startsWith('##') || l.startsWith('**')) {
        flushSection();
        currentTitle = l.replaceAll(RegExp(r'[#*]'), '').trim();
      } else {
        currentLines.add(l);
      }
    }
    flushSection();

    if (sectionWidgets.isEmpty) {
      sectionWidgets.add(
        ReportSectionCard(
          title: 'نتيجة التقرير',
          content: text,
          icon: Icons.article_outlined,
        ),
      );
    }

    return sectionWidgets;
  }

  Widget _buildNoContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AssessmentShadows.card,
      ),
      child: const Column(
        children: [
          Icon(Icons.article_outlined,
              size: 48, color: AssessmentColors.textMuted),
          SizedBox(height: 12),
          Text(
            'لا يوجد محتوى متاح للتقرير.',
            style: TextStyle(
                fontSize: 15,
                fontFamily: 'Cairo',
                color: AssessmentColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Disclaimer ─────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AssessmentColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AssessmentColors.warning.withValues(alpha: 0.3)),
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

  // ── Bottom actions ─────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, String patientName) {
    return Column(
      children: [
        // PDF export button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _exportPdf(context, patientName),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('تحميل PDF',
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
        // Home button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              if (isDoctorView) {
                Navigator.pop(context);
              } else {
                Navigator.popUntil(context, ModalRoute.withName('/patient_dashboard'));
              }
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text('العودة للرئيسية',
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
        const SizedBox(height: 12),
        // Report history link (hide for doctors to keep it simple, or make it pop)
        if (!isDoctorView)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/report_history'),
              icon: const Icon(Icons.history_rounded, size: 20),
              label: const Text('تقاريري السابقة',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14)),
              style: TextButton.styleFrom(
                foregroundColor: AssessmentColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _exportPdf(BuildContext context, String patientName) async {
    final success = await ReportPdfExporter.exportAndShare(
      context: context,
      patientName: patientName,
      reportDate: report.createdAt,
      rawAiReport: report.aiReport,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تعذر إنشاء ملف PDF. حاول مرة أخرى.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AssessmentColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
