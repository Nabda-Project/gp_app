import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF407BFF);
  static const Color secondaryBlue = Color(0xFF00B4D8);
  static const Color darkBlue = Color(0xFF03045E);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF94A3B8);
  static const Color lightGrey = Color(0xFFE2E8F0);
  static const Color accentTeal = Color(0xFF00BFA5);
  static const Color error = Color(0xFFE53935);

  // Gradient colors
  static const Color gradientStart = Color(0xFF407BFF);
  static const Color gradientEnd = Color(0xFF00B4D8);
  static const Color cardGlow = Color(0x1A407BFF);

  // Card shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primaryBlue.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Primary gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
}

class AppStrings {
  static const String appName = "NABDA";
  static const String onboardingTitle = "Your Health, Your Pulse";
  static const String onboardingDesc =
      "Connected care, real-time monitoring, and instant medical support.";
  static const String getStarted = "Get Started";
  static const String roleSelectionTitle = "Who are you?";
  static const String roleDoctor = "Doctor";
  static const String rolePatient = "Patient";
}

class AppAssets {
  // Placeholders - in a real app these would be actual paths
  static const String logo = "assets/images/logo.png";
  static const String doctorIcon = "assets/icons/doctor.png";
  static const String patientIcon = "assets/icons/patient.png";
  static const String onboardingImage = "assets/images/onboarding.png";
}

class AppDimensions {
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 30.0;
}
