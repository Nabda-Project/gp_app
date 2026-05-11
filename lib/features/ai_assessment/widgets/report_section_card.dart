// Reusable widget that renders a single report section as a styled card.
//
// Handles different value types recursively:
// - String: simple text
// - List of Maps: numbered sub-cards (e.g. symptoms)
// - Map: labeled key-value rows
// - List of String/num: bullet list
// - Other: translated text
//
// Empty values are automatically hidden at every level.
import 'package:flutter/material.dart';
import '../utils/report_formatter.dart';
import 'assessment_theme.dart';

class ReportSectionCard extends StatelessWidget {
  final String title;
  final dynamic content;
  final IconData? icon;

  const ReportSectionCard({
    super.key,
    required this.title,
    required this.content,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AssessmentShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: AssessmentColors.primarySurface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AssessmentColors.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: AssessmentColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Section body ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: _buildContent(content),
          ),
        ],
      ),
    );
  }

  // ── Content renderer ─────────────────────────────────────────────────────

  Widget _buildContent(dynamic value) {
    if (value is String) return _buildText(value);
    if (value is num) return _buildText(value.toString());
    if (value is bool) return _buildText(value ? 'نعم' : 'لا');
    if (value is List) return _buildList(value);
    if (value is Map) return _buildMap(value);
    return const SizedBox.shrink();
  }

  Widget _buildText(String text) {
    final display = ReportFormatter.translateValue(text);
    return Text(
      display,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Cairo',
        color: AssessmentColors.textPrimary,
        height: 1.7,
      ),
    );
  }

  Widget _buildList(List list) {
    // Filter out empty items
    final filtered = list.where((e) => !ReportFormatter.isEmpty(e)).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    // Check if it's a list of maps (like symptoms)
    if (filtered.first is Map) {
      return _buildMapList(filtered.cast<Map>());
    }

    // List of primitives → bullet list
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filtered.map((item) {
        final display = ReportFormatter.valueToString(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.circle, size: 6, color: AssessmentColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  display,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Cairo',
                    color: AssessmentColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMapList(List<Map> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) {
        final item = Map<String, dynamic>.from(items[index]);
        // Skip entirely empty items
        if (ReportFormatter.isEmpty(item)) return const SizedBox.shrink();

        // Try to get a "primary" field for the item title
        // For symptoms, use the "symptom" key
        final primaryKey = _findPrimaryKey(item);
        final primaryValue = primaryKey != null ? item[primaryKey] : null;

        return Container(
          margin: EdgeInsets.only(
            bottom: index < items.length - 1 ? 12 : 0,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AssessmentColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AssessmentColors.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numbered title with primary value
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AssessmentColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (primaryValue != null &&
                      !ReportFormatter.isEmpty(primaryValue))
                    Expanded(
                      child: Text(
                        ReportFormatter.valueToString(primaryValue),
                        style: const TextStyle(
                          fontSize: 15,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          color: AssessmentColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              // Additional fields (skip primary and empty)
              ..._buildMapFields(item, skipKey: primaryKey),
            ],
          ),
        );
      }),
    );
  }

  /// Build key-value rows from a Map, skipping empty values and optionally a key.
  List<Widget> _buildMapFields(Map<String, dynamic> map, {String? skipKey}) {
    final widgets = <Widget>[];
    for (final entry in map.entries) {
      if (entry.key == skipKey) continue;
      if (ReportFormatter.isEmpty(entry.value)) continue;

      final label = ReportFormatter.translateField(entry.key);

      // If the value is itself a Map or List, render it recursively
      if (entry.value is Map || entry.value is List) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label:',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    color: AssessmentColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                _buildContent(entry.value),
              ],
            ),
          ),
        );
      } else {
        final display = ReportFormatter.valueToString(entry.value);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    color: AssessmentColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    display,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Cairo',
                      color: AssessmentColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildMap(Map map) {
    final castMap = Map<String, dynamic>.from(map);
    final fields = _buildMapFields(castMap);
    if (fields.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields,
    );
  }

  /// Find the "primary" key in a map item — used as the item title.
  /// For symptom objects this is `symptom`; for others, try common name-like keys.
  static String? _findPrimaryKey(Map<String, dynamic> map) {
    const candidates = ['symptom', 'name', 'title', 'label', 'description'];
    for (final k in candidates) {
      if (map.containsKey(k) && !ReportFormatter.isEmpty(map[k])) return k;
    }
    return null;
  }
}
