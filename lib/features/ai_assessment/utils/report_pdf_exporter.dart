// PDF exporter for AI medical reports.
//
// Generates a professionally formatted, RTL Arabic PDF document
// containing two parts:
// 1. AI Generated Report
// 2. Patient Submitted Assessment Data
//
// Uses `printing` + `pdf` packages with PdfGoogleFonts for Arabic text.
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'report_formatter.dart';
import 'patient_input_formatter.dart';

class ReportPdfExporter {
  ReportPdfExporter._();

  /// Sanitize a name for use in a filename.
  /// Replaces spaces with underscores and removes unsafe characters.
  static String _sanitizeFilename(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF._-]'), '')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Generate and preview/share the report PDF.
  ///
  /// Returns `true` on success, `false` on failure.
  static Future<bool> exportAndShare({
    required BuildContext context,
    required String patientName,
    required DateTime reportDate,
    required String rawAiReport,
    Map<String, dynamic>? patientSubmissionData,
    String? ageDisplay,
    String? genderDisplay,
    String? heightDisplay,
    String? weightDisplay,
    int? reportId,
  }) async {
    try {
      // ── Load Arabic font ────────────────────────────────────────────────
      final pw.Font cairoRegular;
      final pw.Font cairoBold;
      try {
        cairoRegular = await PdfGoogleFonts.cairoRegular();
        cairoBold = await PdfGoogleFonts.cairoBold();
      } catch (e) {
        log('PDF font loading failed: $e', name: 'ReportPdfExporter');
        return false;
      }

      // ── Colors ──────────────────────────────────────────────────────────
      final primaryColor = PdfColor.fromHex('#407BFF');
      final darkColor = PdfColor.fromHex('#1E3A5F');
      final borderColor = PdfColor.fromHex('#E2E8F0');
      final bgLight = PdfColor.fromHex('#EBF1FF');
      final bgSection = PdfColor.fromHex('#F8FAFC');
      final accentGreen = PdfColor.fromHex('#10B981');

      // ── Styles ──────────────────────────────────────────────────────────
      final baseStyle = pw.TextStyle(font: cairoRegular, fontSize: 11);
      final boldStyle = pw.TextStyle(
          font: cairoBold, fontSize: 11, fontWeight: pw.FontWeight.bold);
      final headerStyle = pw.TextStyle(
          font: cairoBold, fontSize: 20, color: primaryColor);
      final sectionTitleStyle = pw.TextStyle(
          font: cairoBold, fontSize: 13, color: primaryColor);
      final labelStyle = pw.TextStyle(
          font: cairoBold, fontSize: 10, color: PdfColor.fromHex('#64748B'));
      final partTitleStyle = pw.TextStyle(
          font: cairoBold, fontSize: 15, color: darkColor);
      final smallStyle = pw.TextStyle(
          font: cairoRegular, fontSize: 9, color: PdfColor.fromHex('#94A3B8'));

      final parsed = ReportFormatter.tryParseJson(rawAiReport);
      final dateStr = ReportFormatter.formatDateArabic(reportDate);
      final content = <pw.Widget>[];

      // ── Professional Header with accent line ────────────────────────────
      content.add(_buildProfessionalHeader(
          patientName, dateStr, headerStyle, boldStyle, baseStyle,
          cairoBold, cairoRegular, smallStyle,
          primaryColor, bgLight, accentGreen,
          ageDisplay: ageDisplay, genderDisplay: genderDisplay,
          heightDisplay: heightDisplay, weightDisplay: weightDisplay,
          reportId: reportId));
      content.add(pw.SizedBox(height: 18));

      // ── PART 1: AI Report ───────────────────────────────────────────────
      content.add(_buildPartTitlePdf('نتيجة التحليل الطبي', partTitleStyle,
          cairoRegular, primaryColor));
      content.add(pw.SizedBox(height: 10));

      if (parsed is Map<String, dynamic>) {
        for (final entry in parsed.entries) {
          if (ReportFormatter.isEmpty(entry.value)) continue;
          final title = ReportFormatter.translateSection(entry.key);
          content.add(_buildPdfSection(
            title: title, value: entry.value,
            titleStyle: sectionTitleStyle, baseStyle: baseStyle,
            boldStyle: boldStyle, labelStyle: labelStyle,
            bgLight: bgLight, borderColor: borderColor,
          ));
          content.add(pw.SizedBox(height: 10));
        }
      } else {
        final text = rawAiReport.trim();
        if (text.isNotEmpty) {
          content.add(pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor),
              borderRadius: pw.BorderRadius.circular(8),
              color: bgSection,
            ),
            child: pw.Text(text, style: baseStyle,
                textDirection: pw.TextDirection.rtl),
          ));
          content.add(pw.SizedBox(height: 10));
        }
      }

      // ── PART 2: Patient Submitted Data ──────────────────────────────────
      if (patientSubmissionData != null && patientSubmissionData.isNotEmpty) {
        final cleanData = Map<String, dynamic>.from(patientSubmissionData);
        cleanData.removeWhere((key, value) =>
            ReportFormatter.isEmpty(value) || key == 'demographics');

        if (cleanData.isNotEmpty) {
          final sections = PatientInputFormatter.buildDisplaySections(cleanData);
          if (sections.isNotEmpty) {
            content.add(pw.SizedBox(height: 10));
            content.add(_buildPartTitlePdf(
                'بيانات التقييم التي أدخلها المريض', partTitleStyle,
                cairoRegular, primaryColor));
            content.add(pw.SizedBox(height: 10));

            for (final section in sections) {
              final title = section.key;
              final data = section.value;

              if (data is String) {
                content.add(_buildPdfSection(
                  title: title, value: data,
                  titleStyle: sectionTitleStyle, baseStyle: baseStyle,
                  boldStyle: boldStyle, labelStyle: labelStyle,
                  bgLight: bgLight, borderColor: borderColor,
                ));
              } else if (data is List<MapEntry<String, String>>) {
                content.add(_buildPdfKeyValueSection(
                  title: title, rows: data,
                  titleStyle: sectionTitleStyle, baseStyle: baseStyle,
                  labelStyle: labelStyle,
                  bgLight: bgLight, borderColor: borderColor,
                ));
              } else if (data is List) {
                content.add(_buildPdfListSection(
                  title: title, items: data,
                  titleStyle: sectionTitleStyle, baseStyle: baseStyle,
                  boldStyle: boldStyle,
                  bgLight: bgLight, borderColor: borderColor,
                ));
              }
              content.add(pw.SizedBox(height: 10));
            }
          }
        }
      }

      // ── Disclaimer ──────────────────────────────────────────────────────
      content.add(pw.SizedBox(height: 6));
      content.add(pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#FFF8E1'),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromHex('#F59E0B')),
        ),
        child: pw.Text(
          'هذا التقرير استرشادي ولا يغني عن استشارة الطبيب.',
          style: pw.TextStyle(font: cairoRegular, fontSize: 10,
              color: PdfColor.fromHex('#92400E')),
          textDirection: pw.TextDirection.rtl,
        ),
      ));

      // ── Assemble ────────────────────────────────────────────────────────
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        theme: pw.ThemeData.withFont(base: cairoRegular, bold: cairoBold),
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => content,
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Column(
            children: [
              pw.Container(
                width: double.infinity,
                height: 1,
                color: borderColor,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
                style: pw.TextStyle(font: cairoRegular, fontSize: 9,
                    color: PdfColors.grey),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ),
      ));

      if (!context.mounted) return false;

      // ── Build filename: {sanitized_name}_report_{id}.pdf ────────────────
      final sanitizedName = _sanitizeFilename(patientName);
      final reportNumber = reportId ?? reportDate.millisecondsSinceEpoch;
      final pdfFilename = '${sanitizedName}_report_$reportNumber';

      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: pdfFilename,
      );
      return true;
    } catch (e, st) {
      log('PDF generation failed: $e\n$st', name: 'ReportPdfExporter');
      return false;
    }
  }

  // ── Professional PDF Header ─────────────────────────────────────────────
  static pw.Widget _buildProfessionalHeader(
    String patientName, String dateStr,
    pw.TextStyle headerStyle, pw.TextStyle boldStyle,
    pw.TextStyle baseStyle, pw.Font cairoBold, pw.Font cairoRegular,
    pw.TextStyle smallStyle,
    PdfColor primaryColor, PdfColor bgLight, PdfColor accentGreen, {
    String? ageDisplay, String? genderDisplay,
    String? heightDisplay, String? weightDisplay,
    int? reportId,
  }) {
    final demoItems = <String>[];
    if (ageDisplay != null) demoItems.add('العمر: $ageDisplay');
    if (genderDisplay != null) demoItems.add('الجنس: $genderDisplay');
    if (heightDisplay != null) demoItems.add('الطول: $heightDisplay');
    if (weightDisplay != null) demoItems.add('الوزن: $weightDisplay');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Accent top bar ──────────────────────────────────────────────
        pw.Container(
          width: double.infinity,
          height: 4,
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primaryColor, PdfColor.fromHex('#6C9BFF')],
            ),
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(height: 14),

        // ── Title row ───────────────────────────────────────────────────
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: bgLight,
            borderRadius: pw.BorderRadius.circular(12),
            border: pw.Border.all(color: PdfColor.fromHex('#C7D7FF'), width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('التقرير الطبي', style: headerStyle,
                      textDirection: pw.TextDirection.rtl),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: accentGreen,
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text('مكتمل',
                        style: pw.TextStyle(font: cairoBold, fontSize: 10,
                            color: PdfColors.white),
                        textDirection: pw.TextDirection.rtl),
                  ),
                ],
              ),

              if (reportId != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('تقرير رقم: $reportId',
                    style: smallStyle,
                    textDirection: pw.TextDirection.rtl),
              ],

              pw.SizedBox(height: 10),

              // ── Separator ─────────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                height: 1,
                color: PdfColor.fromHex('#C7D7FF'),
              ),
              pw.SizedBox(height: 10),

              // ── Patient info grid ─────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('اسم المريض', style: pw.TextStyle(
                            font: cairoRegular, fontSize: 9,
                            color: PdfColor.fromHex('#64748B')),
                            textDirection: pw.TextDirection.rtl),
                        pw.SizedBox(height: 2),
                        pw.Text(patientName, style: boldStyle,
                            textDirection: pw.TextDirection.rtl),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('تاريخ التقرير', style: pw.TextStyle(
                          font: cairoRegular, fontSize: 9,
                          color: PdfColor.fromHex('#64748B')),
                          textDirection: pw.TextDirection.rtl),
                      pw.SizedBox(height: 2),
                      pw.Text(dateStr, style: baseStyle,
                          textDirection: pw.TextDirection.rtl),
                    ],
                  ),
                ],
              ),

              // ── Demographics row ──────────────────────────────────────
              if (demoItems.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  height: 1,
                  color: PdfColor.fromHex('#C7D7FF'),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: demoItems.map((item) {
                    final parts = item.split(': ');
                    return pw.Column(
                      children: [
                        pw.Text(parts[0], style: pw.TextStyle(
                            font: cairoRegular, fontSize: 9,
                            color: PdfColor.fromHex('#64748B')),
                            textDirection: pw.TextDirection.rtl),
                        pw.SizedBox(height: 2),
                        pw.Text(parts.length > 1 ? parts[1] : '',
                            style: pw.TextStyle(font: cairoBold, fontSize: 11),
                            textDirection: pw.TextDirection.rtl),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Part title ──────────────────────────────────────────────────────────
  static pw.Widget _buildPartTitlePdf(
      String title, pw.TextStyle style, pw.Font font, PdfColor primaryColor) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F0F4FF'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border(
          right: pw.BorderSide(color: primaryColor, width: 3),
        ),
      ),
      child: pw.Text(title, style: style, textDirection: pw.TextDirection.rtl),
    );
  }

  // ── Key-value section (patient data) ────────────────────────────────────
  static pw.Widget _buildPdfKeyValueSection({
    required String title,
    required List<MapEntry<String, String>> rows,
    required pw.TextStyle titleStyle,
    required pw.TextStyle baseStyle,
    required pw.TextStyle labelStyle,
    required PdfColor bgLight,
    required PdfColor borderColor,
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: pw.BoxDecoration(
              color: bgLight,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(title, style: titleStyle,
                textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: rows.map((row) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('${row.key}: ${row.value}',
                      style: baseStyle,
                      textDirection: pw.TextDirection.rtl),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── List section (patient data) ─────────────────────────────────────────
  static pw.Widget _buildPdfListSection({
    required String title,
    required List items,
    required pw.TextStyle titleStyle,
    required pw.TextStyle baseStyle,
    required pw.TextStyle boldStyle,
    required PdfColor bgLight,
    required PdfColor borderColor,
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: pw.BoxDecoration(
              color: bgLight,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(title, style: titleStyle,
                textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: boldStyle),
                      pw.Expanded(
                        child: pw.Text(item.toString(), style: baseStyle,
                            textDirection: pw.TextDirection.rtl),
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

  // ── AI report section builder ───────────────────────────────────────────
  static pw.Widget _buildPdfSection({
    required String title, required dynamic value,
    required pw.TextStyle titleStyle, required pw.TextStyle baseStyle,
    required pw.TextStyle boldStyle, required pw.TextStyle labelStyle,
    required PdfColor bgLight, required PdfColor borderColor,
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: pw.BoxDecoration(
              color: bgLight,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(title, style: titleStyle,
                textDirection: pw.TextDirection.rtl),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: _buildPdfValue(value, baseStyle, boldStyle, labelStyle),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfValue(
      dynamic value, pw.TextStyle baseStyle,
      pw.TextStyle boldStyle, pw.TextStyle labelStyle) {
    if (value is String) {
      return pw.Text(ReportFormatter.translateValue(value),
          style: baseStyle, textDirection: pw.TextDirection.rtl);
    }
    if (value is num || value is bool) {
      return pw.Text(ReportFormatter.valueToString(value),
          style: baseStyle, textDirection: pw.TextDirection.rtl);
    }
    if (value is List) {
      final filtered = value.where((e) => !ReportFormatter.isEmpty(e)).toList();
      if (filtered.isEmpty) return pw.SizedBox();
      if (filtered.first is Map) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: List.generate(filtered.length, (i) {
            final item = Map<String, dynamic>.from(filtered[i] as Map);
            return _buildPdfMapItem(item, i + 1, baseStyle, boldStyle, labelStyle);
          }),
        );
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: filtered.map((e) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: boldStyle),
                pw.Expanded(child: pw.Text(
                    ReportFormatter.valueToString(e),
                    style: baseStyle, textDirection: pw.TextDirection.rtl)),
              ],
            ),
          );
        }).toList(),
      );
    }
    if (value is Map) {
      return _buildPdfMapFields(
          Map<String, dynamic>.from(value), baseStyle, boldStyle, labelStyle);
    }
    return pw.SizedBox();
  }

  static pw.Widget _buildPdfMapItem(Map<String, dynamic> item, int index,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle, pw.TextStyle labelStyle) {
    const candidates = ['symptom', 'name', 'title', 'label', 'description'];
    String? primaryKey;
    for (final k in candidates) {
      if (item.containsKey(k) && !ReportFormatter.isEmpty(item[k])) {
        primaryKey = k;
        break;
      }
    }
    final widgets = <pw.Widget>[];
    final titleText = primaryKey != null
        ? '$index. ${ReportFormatter.valueToString(item[primaryKey])}'
        : '$index.';
    widgets.add(pw.Text(titleText, style: boldStyle,
        textDirection: pw.TextDirection.rtl));
    for (final entry in item.entries) {
      if (entry.key == primaryKey) continue;
      if (ReportFormatter.isEmpty(entry.value)) continue;
      final label = ReportFormatter.translateField(entry.key);
      if (entry.value is Map || entry.value is List) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, right: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$label:', style: labelStyle,
                  textDirection: pw.TextDirection.rtl),
              _buildPdfValue(entry.value, baseStyle, boldStyle, labelStyle),
            ],
          ),
        ));
      } else {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, right: 16),
          child: pw.Text(
              '$label: ${ReportFormatter.valueToString(entry.value)}',
              style: baseStyle, textDirection: pw.TextDirection.rtl),
        ));
      }
    }
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFF'),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets),
    );
  }

  static pw.Widget _buildPdfMapFields(Map<String, dynamic> map,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle, pw.TextStyle labelStyle) {
    final widgets = <pw.Widget>[];
    for (final entry in map.entries) {
      if (ReportFormatter.isEmpty(entry.value)) continue;
      final label = ReportFormatter.translateField(entry.key);
      if (entry.value is Map || entry.value is List) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$label:', style: labelStyle,
                  textDirection: pw.TextDirection.rtl),
              pw.SizedBox(height: 2),
              _buildPdfValue(entry.value, baseStyle, boldStyle, labelStyle),
            ],
          ),
        ));
      } else {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
              '$label: ${ReportFormatter.valueToString(entry.value)}',
              style: baseStyle, textDirection: pw.TextDirection.rtl),
        ));
      }
    }
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets);
  }
}
