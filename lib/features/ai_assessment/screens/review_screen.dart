import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../data/cardiac_questions.dart';
import '../widgets/assessment_theme.dart';
import '../widgets/assessment_next_button.dart';
import 'assessment_flow_screen.dart';
import 'report_loading_screen.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = ModalRoute.of(context)!.settings.arguments as AssessmentState;
    final json = state.buildSubmissionJson();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AssessmentColors.background,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionCard(
                      icon: Icons.history_edu_rounded,
                      title: 'التاريخ المرضي',
                      child: _buildHistorySection(json['history'] as Map<String, dynamic>? ?? {}),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      icon: Icons.checklist_rounded,
                      title: 'الأعراض المختارة',
                      child: _buildSymptomList(
                          (json['symptom_selection'] as Map<String, dynamic>?)?['chosen'] as List? ?? []),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      icon: Icons.assignment_rounded,
                      title: 'تفاصيل الأعراض',
                      child: _buildSymptomDetailSection(
                          json['symptom_detail'] as Map<String, dynamic>? ?? {}),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AssessmentColors.warning,
                      title: 'أسئلة مهمة',
                      child: _buildRedFlags(json['red_flags'] as Map<String, dynamic>? ?? {}),
                    ),
                    const SizedBox(height: 16),
                    _sectionCard(
                      icon: Icons.notes_rounded,
                      title: 'ملاحظات إضافية',
                      child: _buildFreeText(
                          (json['free_text'] as Map<String, dynamic>?)?['additional'] as String? ?? ''),
                    ),
                    const SizedBox(height: 16),
                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AssessmentColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AssessmentColors.warning.withOpacity(0.3)),
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
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            AssessmentNextButton(
              label: 'إرسال وإنشاء التقرير',
              icon: Icons.send_rounded,
              onPressed: () {
                // Debug logging — verify final JSON before submission
                log(
                  const JsonEncoder.withIndent('  ').convert(json),
                  name: 'AI_ASSESSMENT_FINAL_JSON',
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportLoadingScreen(
                      submissionJson: json,
                    ),
                  ),
                );
              },
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
            offset: const Offset(0, 8),
          ),
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
              Text(
                'مراجعة الإجابات',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo'),
              ),
              Text(
                'تحقق من إجاباتك قبل الإرسال',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Cairo'),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AssessmentShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: (iconColor ?? AssessmentColors.primary).withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: iconColor ?? AssessmentColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: iconColor ?? AssessmentColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(Map<String, dynamic> history) {
    final items = <Widget>[];

    void addItem(String label, dynamic value) {
      if (value == null) return;
      String display;
      if (value is List) {
        display = value.join('، ');
      } else {
        display = value.toString();
      }
      items.add(_reviewRow(label, display));
    }

    addItem('التشخيصات القلبية السابقة', history['known_cardiac']);
    addItem('فحوصات القلب السابقة', history['prior_workup']);
    addItem('الحالات المزمنة', history['chronic_conditions']);
    addItem('الأدوية', history['medications']);
    addItem('الالتزام بالدواء', history['med_adherence']);
    addItem('التاريخ العائلي', history['family_history']);
    addItem('نمط الحياة', history['lifestyle']);

    if (items.isEmpty) {
      return const Text('لا توجد بيانات',
          style: TextStyle(fontFamily: 'Cairo', color: AssessmentColors.textMuted));
    }
    return Column(children: items);
  }

  Widget _buildSymptomList(List chosen) {
    if (chosen.isEmpty) {
      return const Text('لم يتم اختيار أعراض',
          style: TextStyle(fontFamily: 'Cairo', color: AssessmentColors.textMuted));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chosen.map((code) {
        final label = symptomLabels[code as String] ?? code;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AssessmentColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AssessmentColors.primary.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Cairo',
                color: AssessmentColors.primary),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSymptomDetailSection(Map<String, dynamic> details) {
    if (details.isEmpty) {
      return const Text('لا توجد تفاصيل',
          style: TextStyle(fontFamily: 'Cairo', color: AssessmentColors.textMuted));
    }
    final items = <Widget>[];
    for (final entry in details.entries) {
      final code = entry.key;
      final label = symptomLabels[code] ?? code;
      final detail = entry.value;
      items.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AssessmentColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: AssessmentColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              if (detail is Map<String, dynamic>)
                ...detail.entries.map((d) => _reviewRow(
                      d.key,
                      d.value is List ? (d.value as List).join('، ') : d.value,
                    ))
              else
                Text(detail.toString(),
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AssessmentColors.textPrimary)),
            ],
          ),
        ),
      );
    }
    return Column(children: items);
  }

  Widget _buildRedFlags(Map<String, dynamic> redFlags) {
    final items = <Widget>[];
    if (redFlags['exertional_chest'] != null) {
      items.add(_reviewRow('ألم صدر مع المجهود', redFlags['exertional_chest']));
    }
    if (redFlags['syncope_exertion'] != null) {
      items.add(_reviewRow('إغماء أثناء الرياضة', redFlags['syncope_exertion']));
    }
    if (items.isEmpty) {
      return const Text('لا توجد بيانات',
          style: TextStyle(fontFamily: 'Cairo', color: AssessmentColors.textMuted));
    }
    return Column(children: items);
  }

  Widget _buildFreeText(String text) {
    return Text(
      text.isEmpty ? 'لا توجد ملاحظات إضافية' : text,
      style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: text.isEmpty
              ? AssessmentColors.textMuted
              : AssessmentColors.textPrimary,
          height: 1.6),
    );
  }

  Widget _reviewRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
                color: AssessmentColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Cairo',
                  color: AssessmentColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
