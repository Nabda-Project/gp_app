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
import '../screens/doctor/doctor_dashboard_screen.dart';
import '../screens/doctor/patient_detail_screen.dart';
import '../screens/doctor/patient_chat_screen.dart';
import '../screens/role_selection/role_selection_screen.dart';

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
  static const String roleSelection = '/role_selection';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    auth: (context) => const AuthScreen(),
    patientDashboard: (context) => const PatientDashboardScreen(),
    chatbot: (context) => const ChatbotScreen(),
    notifications: (context) => const NotificationsScreen(),
    doctorChat: (context) => const DoctorChatScreen(),
    followUps: (context) => const FollowUpsScreen(),
    profile: (context) => const ProfileScreen(),
    settings: (context) => const SettingsScreen(),
    // Doctor screens
    doctorDashboard: (context) => const DoctorDashboardScreen(),
    patientDetail: (context) => const PatientDetailScreen(),
    patientChat: (context) => const PatientChatScreen(),
    roleSelection: (context) => const RoleSelectionScreen(),
  };
}
