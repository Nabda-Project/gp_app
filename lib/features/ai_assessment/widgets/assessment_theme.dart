/// Assessment theme constants for the cardiac assessment feature.
/// Colors aligned with the main dashboard blue/cyan palette.
import 'package:flutter/material.dart';

class AssessmentColors {
  // Primary – matches dashboard AppColors.primaryBlue (#407BFF)
  static const Color primary = Color(0xFF407BFF);
  static const Color primaryDark = Color(0xFF2D5FC4);
  static const Color primaryLight = Color(0xFFB3CDFF);
  static const Color primarySurface = Color(0xFFEBF1FF);

  // Accent – matches dashboard secondaryBlue / cyan (#00B4D8)
  static const Color accent = Color(0xFF00B4D8);
  static const Color accentLight = Color(0xFFD0F4FF);

  // Backgrounds
  static const Color background = Color(0xFFF0F5FF);
  static const Color cardBg = Colors.white;
  static const Color surfaceLight = Color(0xFFF8FAFF);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);

  // Selection
  static const Color selected = Color(0xFF407BFF);
  static const Color selectedBg = Color(0xFFEBF1FF);
  static const Color unselected = Color(0xFFE2E8F0);

  // Gradients – blue → cyan matching dashboard primaryGradient
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF407BFF), Color(0xFF00B4D8)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF407BFF), Color(0xFF5B9BFF)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
  );

  static const LinearGradient loadingGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF407BFF), Color(0xFF00B4D8), Color(0xFF1E3A5F)],
  );
}

class AssessmentShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AssessmentColors.primary.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get selected => [
    BoxShadow(
      color: AssessmentColors.primary.withOpacity(0.20),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: AssessmentColors.primary.withOpacity(0.30),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
