// Redesigned AI medical report display screen.
//
// Displays two parts:
// 1. AI Generated Report (from aiReport)
// 2. Patient Submitted Assessment Data (from submissionJson or patientRequestData or patientInput)
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/assessment_models.dart';
import '../utils/report_formatter.dart';
import '../utils/patient_input_formatter.dart';
import '../utils/report_pdf_exporter.dart';
import '../widgets/assessment_theme.dart';
import '../widgets/report_section_card.dart';
import '../../../services/storage_service.dart';

class ReportResultScreen extends StatelessWidget {
  final AiConsultResponse report;
  final String? patientNameOverride;
  final bool isDoctorView;
  /// Original submission JSON from the assessment flow (preferred source).
  final Map<String, dynamic>? submissionJson;

  const ReportResultScreen({
    super.key,
    required this.report,
    this.patientNameOverride,
    this.isDoctorView = false,
    this.submissionJson,
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
    final patientName = patientNameOverride ??
        report.patientName ??
        ((user?.fullName != null && user!.fullName.trim().isNotEmpty)
            ? user.fullName
            : 'المريض');

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
                    const SizedBox(height: 20),

                    // ── PART 1: AI Generated Report ──────────────────
                    _buildPartTitle(
                      icon: Icons.smart_toy_outlined,
                      title: 'نتيجة التحليل الطبي',
                    ),
                    const SizedBox(height: 12),
                    ..._buildAiReportSections(),
                    const SizedBox(height: 24),

                    // ── PART 2: Patient Submitted Data ───────────────
                    ..._buildPatientDataPart(),
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

  // ── Part title widget ──────────────────────────────────────────────────
  Widget _buildPartTitle({required IconData icon, required String title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AssessmentColors.primary.withValues(alpha: 0.1),
            AssessmentColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AssessmentColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AssessmentColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: AssessmentColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20, right: 20, bottom: 20,
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
            blurRadius: 20, offset: const Offset(0, 8),
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
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                Text('تم إنشاء تقريرك بنجاح',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13,
                        fontFamily: 'Cairo')),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (isDoctorView) {
                Navigator.pop(context);
              } else {
                Navigator.popUntil(
                    context, ModalRoute.withName('/patient_dashboard'));
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

    // Resolve demographics
    String? genderDisplay;
    String? ageDisplay;
    String? heightDisplay;
    String? weightDisplay;

    if (!isDoctorView) {
      // Patient view: read from local storage
      final user = StorageService.getUser();
      if (user != null) {
        if (user.gender != null && user.gender!.isNotEmpty) {
          genderDisplay = user.gender == 'MALE' ? 'ذكر' : (user.gender == 'FEMALE' ? 'أنثى' : user.gender);
        }
        if (user.dateOfBirth != null) {
          final now = DateTime.now();
          final age = now.year - user.dateOfBirth!.year -
              ((now.month < user.dateOfBirth!.month ||
                  (now.month == user.dateOfBirth!.month && now.day < user.dateOfBirth!.day)) ? 1 : 0);
          ageDisplay = '$age سنة';
        }
        if (user.height != null && user.height! > 0) {
          heightDisplay = '${user.height!.toStringAsFixed(0)} سم';
        }
        if (user.weight != null && user.weight! > 0) {
          weightDisplay = '${user.weight!.toStringAsFixed(0)} كجم';
        }
      }
    } else {
      // Doctor view: use stored demographics from the report (DB snapshot)
      if (report.patientAge != null) {
        ageDisplay = '${report.patientAge} سنة';
      }
      if (report.patientGender != null && report.patientGender!.isNotEmpty) {
        genderDisplay = report.patientGender == 'MALE' ? 'ذكر' : (report.patientGender == 'FEMALE' ? 'أنثى' : report.patientGender);
      }
      if (report.patientHeight != null && report.patientHeight! > 0) {
        heightDisplay = '${report.patientHeight!.toStringAsFixed(0)} سم';
      }
      if (report.patientWeight != null && report.patientWeight! > 0) {
        weightDisplay = '${report.patientWeight!.toStringAsFixed(0)} كجم';
      }
    }

    final hasDemographics = genderDisplay != null || ageDisplay != null ||
        heightDisplay != null || weightDisplay != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AssessmentShadows.card,
      ),
      child: Column(
        children: [
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
                        style: TextStyle(fontSize: 12, fontFamily: 'Cairo',
                            color: AssessmentColors.textMuted)),
                    Text(patientName,
                        style: const TextStyle(fontSize: 16, fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            color: AssessmentColors.textPrimary)),
                  ],
                ),
              ),
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
                    Text('مكتمل',
                        style: TextStyle(fontSize: 12, fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: AssessmentColors.success)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AssessmentColors.primary.withValues(alpha: 0.06)),
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
                      style: TextStyle(fontSize: 12, fontFamily: 'Cairo',
                          color: AssessmentColors.textMuted)),
                  Text(dateStr,
                      style: const TextStyle(fontSize: 15, fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          color: AssessmentColors.textPrimary)),
                ],
              ),
            ],
          ),
          // Demographics grid
          if (hasDemographics) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AssessmentColors.primary.withValues(alpha: 0.06)),
            const SizedBox(height: 14),
            Row(
              children: [
                if (ageDisplay != null)
                  Expanded(child: _buildDemoItem(Icons.cake_outlined, 'العمر', ageDisplay)),
                if (genderDisplay != null)
                  Expanded(child: _buildDemoItem(Icons.wc_outlined, 'الجنس', genderDisplay)),
                if (heightDisplay != null)
                  Expanded(child: _buildDemoItem(Icons.height_outlined, 'الطول', heightDisplay)),
                if (weightDisplay != null)
                  Expanded(child: _buildDemoItem(Icons.monitor_weight_outlined, 'الوزن', weightDisplay)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDemoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AssessmentColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, fontFamily: 'Cairo',
                color: AssessmentColors.textMuted)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: AssessmentColors.textPrimary)),
      ],
    );
  }

  // ── PART 1: AI Report sections ─────────────────────────────────────────

  List<Widget> _buildAiReportSections() {
    final parsed = ReportFormatter.tryParseJson(report.aiReport);
    if (parsed is Map<String, dynamic>) {
      return _buildJsonSections(parsed);
    }
    return _buildTextSections(report.aiReport);
  }

  List<Widget> _buildJsonSections(Map<String, dynamic> json) {
    final widgets = <Widget>[];
    for (final entry in json.entries) {
      if (ReportFormatter.isEmpty(entry.value)) continue;
      final title = ReportFormatter.translateSection(entry.key);
      final icon = _sectionIcons[entry.key.toLowerCase()];
      widgets.add(ReportSectionCard(title: title, content: entry.value, icon: icon));
    }
    if (widgets.isEmpty) widgets.add(_buildNoContent());
    return widgets;
  }

  List<Widget> _buildTextSections(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [_buildNoContent()];

    final lines = trimmed.split('\n');
    final sectionWidgets = <Widget>[];
    String? currentTitle;
    final currentLines = <String>[];

    void flushSection() {
      if (currentLines.isEmpty) return;
      sectionWidgets.add(ReportSectionCard(
        title: currentTitle ?? 'التقرير',
        content: currentLines.join('\n'),
        icon: Icons.article_outlined,
      ));
      currentLines.clear();
      currentTitle = null;
    }

    for (final line in lines) {
      final l = line.trim();
      if (l.isEmpty) continue;
      if (l.startsWith('##') || l.startsWith('**')) {
        flushSection();
        currentTitle = l.replaceAll(RegExp(r'[#*]'), '').trim();
      } else {
        currentLines.add(l);
      }
    }
    flushSection();

    if (sectionWidgets.isEmpty) {
      sectionWidgets.add(ReportSectionCard(
          title: 'نتيجة التقرير', content: text, icon: Icons.article_outlined));
    }
    return sectionWidgets;
  }

  // ── PART 2: Patient submitted data ─────────────────────────────────────

  List<Widget> _buildPatientDataPart() {
    // Determine source: prefer submissionJson, then patientRequestData, then patientInput
    Map<String, dynamic>? data = submissionJson;
    if (data == null && report.patientRequestData != null) {
      try {
        final parsed = jsonDecode(report.patientRequestData!);
        if (parsed is Map<String, dynamic>) data = parsed;
      } catch (_) {}
    }
    data ??= PatientInputFormatter.tryParseInput(report.patientInput);

    if (data == null || data.isEmpty) return [];

    // Remove demographics=null and other empty top-level entries
    data.removeWhere((key, value) =>
        ReportFormatter.isEmpty(value) || key == 'demographics');

    if (data.isEmpty) return [];

    final sections = PatientInputFormatter.buildDisplaySections(data);
    if (sections.isEmpty) return [];

    final widgets = <Widget>[
      _buildPartTitle(
        icon: Icons.assignment_outlined,
        title: 'بيانات التقييم التي أدخلها المريض',
      ),
      const SizedBox(height: 12),
    ];

    for (final section in sections) {
      final title = section.key;
      final content = section.value;

      if (content is String) {
        // Simple text section (e.g. free text)
        widgets.add(ReportSectionCard(
          title: title,
          content: content,
          icon: Icons.notes_rounded,
        ));
      } else if (content is List<MapEntry<String, String>>) {
        // Key-value pairs section
        widgets.add(_buildKeyValueCard(title, content));
      } else if (content is List) {
        // List of symptom names
        widgets.add(_buildListCard(title, content));
      }
    }

    widgets.add(const SizedBox(height: 8));
    return widgets;
  }

  Widget _buildKeyValueCard(String title, List<MapEntry<String, String>> rows) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AssessmentShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: AssessmentColors.primarySurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo', color: AssessmentColors.primary)),
          ),
          // Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                final idx = entry.key;
                final row = entry.value;
                return Column(
                  children: [
                    if (idx > 0)
                      Divider(height: 16,
                          color: AssessmentColors.primary.withValues(alpha: 0.06)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 130,
                          child: Text(row.key,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  fontFamily: 'Cairo',
                                  color: AssessmentColors.textMuted)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(row.value,
                              style: const TextStyle(
                                  fontSize: 13, fontFamily: 'Cairo',
                                  color: AssessmentColors.textPrimary,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, List items) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo', color: AssessmentColors.primary)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: AssessmentColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item.toString(),
                            style: const TextStyle(
                                fontSize: 14, fontFamily: 'Cairo',
                                color: AssessmentColors.textPrimary,
                                height: 1.5)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoContent() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: AssessmentShadows.card,
      ),
      child: const Column(
        children: [
          Icon(Icons.article_outlined, size: 48, color: AssessmentColors.textMuted),
          SizedBox(height: 12),
          Text('لا يوجد محتوى متاح للتقرير.',
              style: TextStyle(fontSize: 15, fontFamily: 'Cairo',
                  color: AssessmentColors.textSecondary)),
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
          Icon(Icons.info_outline_rounded, color: AssessmentColors.warning, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'هذا التقرير استرشادي ولا يغني عن استشارة الطبيب.',
              style: TextStyle(fontSize: 13, fontFamily: 'Cairo',
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              if (isDoctorView) {
                Navigator.pop(context);
              } else {
                Navigator.popUntil(
                    context, ModalRoute.withName('/patient_dashboard'));
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
        if (!isDoctorView)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/report_history'),
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
    // Resolve patient data for PDF
    Map<String, dynamic>? patientData = submissionJson;
    if (patientData == null && report.patientRequestData != null) {
      try {
        final parsed = jsonDecode(report.patientRequestData!);
        if (parsed is Map<String, dynamic>) patientData = parsed;
      } catch (_) {}
    }
    patientData ??= PatientInputFormatter.tryParseInput(report.patientInput);

    // Resolve demographics for PDF header
    String? ageDisplay;
    String? genderDisplay;
    String? heightDisplay;
    String? weightDisplay;

    if (!isDoctorView) {
      final user = StorageService.getUser();
      if (user != null) {
        if (user.gender != null && user.gender!.isNotEmpty) {
          genderDisplay = user.gender == 'MALE' ? 'ذكر' : (user.gender == 'FEMALE' ? 'أنثى' : user.gender);
        }
        if (user.dateOfBirth != null) {
          final now = DateTime.now();
          final age = now.year - user.dateOfBirth!.year -
              ((now.month < user.dateOfBirth!.month ||
                  (now.month == user.dateOfBirth!.month && now.day < user.dateOfBirth!.day)) ? 1 : 0);
          ageDisplay = '$age سنة';
        }
        if (user.height != null && user.height! > 0) {
          heightDisplay = '${user.height!.toStringAsFixed(0)} سم';
        }
        if (user.weight != null && user.weight! > 0) {
          weightDisplay = '${user.weight!.toStringAsFixed(0)} كجم';
        }
      }
    } else {
      // Doctor view: use stored demographics from the report
      if (report.patientAge != null) {
        ageDisplay = '${report.patientAge} سنة';
      }
      if (report.patientGender != null && report.patientGender!.isNotEmpty) {
        genderDisplay = report.patientGender == 'MALE' ? 'ذكر' : (report.patientGender == 'FEMALE' ? 'أنثى' : report.patientGender);
      }
      if (report.patientHeight != null && report.patientHeight! > 0) {
        heightDisplay = '${report.patientHeight!.toStringAsFixed(0)} سم';
      }
      if (report.patientWeight != null && report.patientWeight! > 0) {
        weightDisplay = '${report.patientWeight!.toStringAsFixed(0)} كجم';
      }
    }

    final success = await ReportPdfExporter.exportAndShare(
      context: context,
      patientName: patientName,
      reportDate: report.createdAt,
      rawAiReport: report.aiReport,
      patientSubmissionData: patientData,
      ageDisplay: ageDisplay,
      genderDisplay: genderDisplay,
      heightDisplay: heightDisplay,
      weightDisplay: weightDisplay,
      reportId: report.id,
    );

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تعذر إنشاء ملف PDF. حاول مرة أخرى.',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AssessmentColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
