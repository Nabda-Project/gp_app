// PDF exporter for AI medical reports.
//
// Generates a professionally formatted, RTL Arabic PDF document
// containing all non-empty report sections with proper styling.
//
// Uses `printing` + `pdf` packages with PdfGoogleFonts for Arabic text.
// TODO: For production / offline support, bundle the Cairo .ttf font
//       in assets/fonts/ instead of relying on Google Fonts (network required
//       on first generation; cached afterwards).
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/report_formatter.dart';

class ReportPdfExporter {
  ReportPdfExporter._();

  /// Generate and preview/share the report PDF.
  ///
  /// Returns `true` on success, `false` on failure.
  /// The caller should show a SnackBar on failure.
  static Future<bool> exportAndShare({
    required BuildContext context,
    required String patientName,
    required DateTime reportDate,
    required String rawAiReport,
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

      // ── Parse report ────────────────────────────────────────────────────
      final parsed = ReportFormatter.tryParseJson(rawAiReport);

      // ── Build PDF ───────────────────────────────────────────────────────
      final pdf = pw.Document();
      final dateStr = ReportFormatter.formatDateArabic(reportDate);

      final baseStyle = pw.TextStyle(font: cairoRegular, fontSize: 12);
      final boldStyle =
          pw.TextStyle(font: cairoBold, fontSize: 12, fontWeight: pw.FontWeight.bold);
      final headerStyle = pw.TextStyle(
        font: cairoBold,
        fontSize: 22,
        color: PdfColor.fromHex('#407BFF'),
      );
      final sectionTitleStyle = pw.TextStyle(
        font: cairoBold,
        fontSize: 14,
        color: PdfColor.fromHex('#407BFF'),
      );
      final labelStyle = pw.TextStyle(
        font: cairoBold,
        fontSize: 11,
        color: PdfColor.fromHex('#64748B'),
      );

      final content = <pw.Widget>[];

      // ── Header ──────────────────────────────────────────────────────────
      content.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#EBF1FF'),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('التقرير الطبي', style: headerStyle),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('اسم المريض: $patientName', style: boldStyle),
                  pw.Container(
                    padding:
                        const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#10B981'),
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Text(
                      'مكتمل',
                      style: pw.TextStyle(
                        font: cairoBold,
                        fontSize: 11,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('تاريخ التقرير: $dateStr', style: baseStyle),
            ],
          ),
        ),
      );
      content.add(pw.SizedBox(height: 16));

      // ── Report sections ─────────────────────────────────────────────────
      if (parsed is Map<String, dynamic>) {
        for (final entry in parsed.entries) {
          if (ReportFormatter.isEmpty(entry.value)) continue;
          final title = ReportFormatter.translateSection(entry.key);
          content.add(_buildPdfSection(
            title: title,
            value: entry.value,
            titleStyle: sectionTitleStyle,
            baseStyle: baseStyle,
            boldStyle: boldStyle,
            labelStyle: labelStyle,
          ));
          content.add(pw.SizedBox(height: 10));
        }
      } else {
        // Plain text / markdown fallback
        final text = rawAiReport.trim();
        if (text.isNotEmpty) {
          content.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(text, style: baseStyle, textDirection: pw.TextDirection.rtl),
            ),
          );
          content.add(pw.SizedBox(height: 10));
        }
      }

      // ── Disclaimer ──────────────────────────────────────────────────────
      content.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FFF8E1'),
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColor.fromHex('#F59E0B')),
          ),
          child: pw.Text(
            'هذا التقرير استرشادي ولا يغني عن استشارة الطبيب.',
            style: pw.TextStyle(font: cairoRegular, fontSize: 11, color: PdfColor.fromHex('#92400E')),
            textDirection: pw.TextDirection.rtl,
          ),
        ),
      );

      // ── Assemble pages ──────────────────────────────────────────────────
      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: cairoRegular, bold: cairoBold),
          textDirection: pw.TextDirection.rtl,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (_) => content,
          footer: (ctx) => pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}',
              style: pw.TextStyle(font: cairoRegular, fontSize: 9, color: PdfColors.grey),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ),
      );

      // ── Show preview / share ────────────────────────────────────────────
      if (!context.mounted) return false;
      await Printing.layoutPdf(
        onLayout: (_) => pdf.save(),
        name: 'تقرير_طبي_${reportDate.millisecondsSinceEpoch}',
      );

      return true;
    } catch (e, st) {
      log('PDF generation failed: $e\n$st', name: 'ReportPdfExporter');
      return false;
    }
  }

  // ── PDF section builder ─────────────────────────────────────────────────

  static pw.Widget _buildPdfSection({
    required String title,
    required dynamic value,
    required pw.TextStyle titleStyle,
    required pw.TextStyle baseStyle,
    required pw.TextStyle boldStyle,
    required pw.TextStyle labelStyle,
  }) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Section title
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EBF1FF'),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(title, style: titleStyle, textDirection: pw.TextDirection.rtl),
          ),
          // Section content
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: _buildPdfValue(value, baseStyle, boldStyle, labelStyle),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfValue(
    dynamic value,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
    pw.TextStyle labelStyle,
  ) {
    if (value is String) {
      final display = ReportFormatter.translateValue(value);
      return pw.Text(display, style: baseStyle, textDirection: pw.TextDirection.rtl);
    }
    if (value is num || value is bool) {
      return pw.Text(
        ReportFormatter.valueToString(value),
        style: baseStyle,
        textDirection: pw.TextDirection.rtl,
      );
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

      // Primitive list
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: filtered.map((e) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: boldStyle),
                pw.Expanded(
                  child: pw.Text(
                    ReportFormatter.valueToString(e),
                    style: baseStyle,
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
    if (value is Map) {
      final castMap = Map<String, dynamic>.from(value);
      return _buildPdfMapFields(castMap, baseStyle, boldStyle, labelStyle);
    }
    return pw.SizedBox();
  }

  static pw.Widget _buildPdfMapItem(
    Map<String, dynamic> item,
    int index,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
    pw.TextStyle labelStyle,
  ) {
    // Find primary key
    const candidates = ['symptom', 'name', 'title', 'label', 'description'];
    String? primaryKey;
    for (final k in candidates) {
      if (item.containsKey(k) && !ReportFormatter.isEmpty(item[k])) {
        primaryKey = k;
        break;
      }
    }

    final widgets = <pw.Widget>[];

    // Header line
    final titleText = primaryKey != null
        ? '$index. ${ReportFormatter.valueToString(item[primaryKey])}'
        : '$index.';
    widgets.add(pw.Text(titleText, style: boldStyle, textDirection: pw.TextDirection.rtl));

    // Remaining fields
    for (final entry in item.entries) {
      if (entry.key == primaryKey) continue;
      if (ReportFormatter.isEmpty(entry.value)) continue;
      final label = ReportFormatter.translateField(entry.key);
      if (entry.value is Map || entry.value is List) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, right: 16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('$label:', style: labelStyle, textDirection: pw.TextDirection.rtl),
                _buildPdfValue(entry.value, baseStyle, boldStyle, labelStyle),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2, right: 16),
            child: pw.Text(
              '$label: ${ReportFormatter.valueToString(entry.value)}',
              style: baseStyle,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        );
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
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  static pw.Widget _buildPdfMapFields(
    Map<String, dynamic> map,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
    pw.TextStyle labelStyle,
  ) {
    final widgets = <pw.Widget>[];
    for (final entry in map.entries) {
      if (ReportFormatter.isEmpty(entry.value)) continue;
      final label = ReportFormatter.translateField(entry.key);
      if (entry.value is Map || entry.value is List) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('$label:', style: labelStyle, textDirection: pw.TextDirection.rtl),
                pw.SizedBox(height: 2),
                _buildPdfValue(entry.value, baseStyle, boldStyle, labelStyle),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              '$label: ${ReportFormatter.valueToString(entry.value)}',
              style: baseStyle,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        );
      }
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
