import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/patient/patient_dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/patient/chatbot_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/patient/doctor_chat_screen.dart';
import '../screens/patient/follow_ups_screen.dart';
import '../screens/patient/medical_history_screen.dart';
import '../screens/doctor/doctor_dashboard_screen.dart';
import '../screens/doctor/patient_detail_screen.dart';
import '../screens/doctor/patient_chat_screen.dart';
import '../screens/doctor/doctor_appointments_screen.dart';
import '../screens/role_selection/role_selection_screen.dart';
import 'app_page_route.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String patientDashboard = '/patient_dashboard';
  static const String chatbot = '/chatbot';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String doctorChat = '/doctor_chat';
  static const String followUps = '/follow_ups';
  // Doctor routes
  static const String doctorDashboard = '/doctor_dashboard';
  static const String patientDetail = '/patient_detail';
  static const String patientChat = '/patient_chat';
  static const String doctorAppointments = '/doctor_appointments';
  static const String roleSelection = '/role_selection';
  static const String medicalHistory = '/medical_history';

  // Keep routes map for initial route
  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
  };

  // Use onGenerateRoute for custom page transitions
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    Widget? page;

    switch (settings.name) {
      case splash:
        page = const SplashScreen();
        break;
      case onboarding:
        page = const OnboardingScreen();
        break;
      case auth:
        page = const AuthScreen();
        break;
      case patientDashboard:
        page = const PatientDashboardScreen();
        break;
      case chatbot:
        page = const ChatbotScreen();
        break;
      case notifications:
        page = const NotificationsScreen();
        break;
      case doctorChat:
        final args = settings.arguments as Map<String, dynamic>?;
        page = DoctorChatScreen(
          doctorName: args?['doctorName'] as String?,
          doctorId: args?['doctorId'] as int?,
        );
        break;
      case followUps:
        page = const FollowUpsScreen();
        break;
      case profile:
        page = const ProfileScreen();
        break;
      case AppRoutes.settings:
        page = const SettingsScreen();
        break;
      case doctorDashboard:
        page = const DoctorDashboardScreen();
        break;
      case patientDetail:
        page = const PatientDetailScreen();
        break;
      case patientChat:
        page = const PatientChatScreen();
        break;
      case doctorAppointments:
        page = const DoctorAppointmentsScreen();
        break;
      case roleSelection:
        page = const RoleSelectionScreen();
        break;
      case medicalHistory:
        page = const MedicalHistoryScreen();
        break;
    }

    if (page != null) {
      return AppPageRoute(page: page, settings: settings);
    }

    return null;
  }
}
