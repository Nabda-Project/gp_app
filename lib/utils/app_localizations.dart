import 'package:flutter/material.dart';
import '../services/translation_service.dart';

/// Enhanced localization class with Google Translate fallback
class AppLocalizations {
  final Locale locale;

  // Cache for dynamically translated strings
  static final Map<String, Map<String, String>> _translationCache = {
    'en': {},
    'ar': {},
  };

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Predefined translations
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'HealthSync',
      // Onboarding
      'getStarted': 'Get Started',
      'onboardingTitle': 'Your Health, Your Hands',
      'onboardingSubtitle':
          'Monitor your vitals, manage your records, and connect with doctors easily.',

      // Auth
      'login': 'Login',
      'createAccount': 'Create Account',
      'accessAccount': 'Access your HealthSync account',
      'emailAddress': 'Email Address',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'fullName': 'Full Name',
      'medicalLicense': 'Medical License Number',
      'forgotPassword': 'Forgot Password?',
      'orLoginWith': 'Or login with',
      'or': 'OR',
      'continueWithGoogle': 'Continue with Google',
      'processingLogin': 'Processing Login...',
      'creatingAccount': 'Creating Account...',
      'patient': 'Patient',
      'doctor': 'Doctor',
      'enterEmail': 'Please enter your email',
      'validEmail': 'Please enter a valid email',
      'enterPassword': 'Please enter your password',
      'passwordLength': 'Password must be at least 6 characters',
      'passwordLength8': 'Password must be at least 8 characters',
      'confirmPasswordReq': 'Please confirm your password',
      'passwordsNoMatch': 'Passwords do not match',
      'enterName': 'Please enter your full name',
      'enterLicense': 'Please enter license number',
      'resetPassword': 'Reset Password',
      'resetPasswordDesc':
          'Enter your email address and we\'ll send you a link to reset your password.',
      'sendResetLink': 'Send Reset Link',

      // Dashboard
      'hello': 'Hello',
      'dashboard': 'Dashboard',
      'vitals': 'Vitals',
      'assistant': 'Assistant',
      'profile': 'Profile',
      'myProfile': 'My Profile',
      'currentHealthStatus': 'Current Health Status',
      'normal': 'Normal',
      'warning': 'Warning',
      'critical': 'Critical',
      'heartRate': 'Heart Rate',
      'bloodOxygen': 'Blood Oxygen',
      'bloodPressure': 'BP (Est)',
      'nextFollowUp': 'Next Follow-up',
      'seeAll': 'See All',
      'vitalsComingSoon': 'Vitals History (Coming Soon)',
      'view': 'View',

      // Doctor Dashboard
      'needAttention': 'Need Attention',
      'criticalAlert': 'Critical Alert',
      'patientsNeedAttention': 'patient(s) need immediate attention',

      // Profile & Settings
      'settings': 'Settings',
      'medicalHistory': 'Medical History',
      'privacySecurity': 'Privacy & Security',
      'helpSupport': 'Help & Support',
      'guestUser': 'Guest User',
      'noEmail': 'No Email',
      'notifications': 'Notifications',
      'notificationsDesc': 'Receive alerts and reminders',
      'language': 'Language',
      'logout': 'Logout',
      'logoutConfirm': 'Are you sure you want to log out?',
      'cancel': 'Cancel',
      'notificationsTitle': 'Notifications',
      'noNotifications': 'No new notifications',
      'markAllRead': 'Mark all as read',
      'doctorChatTitle': 'Chat with Dr. Sarah',
      'typeDoctorMessage': 'Write your message...',
      'doctorResponse':
          'Hello! I received your message. I will check your vitals and get back to you shortly.',
      'chat': 'Chat',

      // Doctor screens
      'doctorDashboard': 'Doctor Dashboard',
      'myPatients': 'My Patients',
      'totalPatients': 'Total Patients',
      'pendingMessages': 'Pending Messages',
      'todayAppointments': "Today's Appointments",
      'recentPatients': 'Recent Patients',
      'searchPatients': 'Search patients...',
      'viewPatient': 'View Patient',
      'sendMessage': 'Send Message',
      'patientDetails': 'Patient Details',
      'lastUpdate': 'Last Update',
      'typePatientMessage': 'Write a message to patient...',
      'vitalsHistory': 'Vitals History',

      // Medical History
      'conditions': 'Conditions',
      'medications': 'Medications',
      'allergies': 'Allergies',
      'procedures': 'Procedures',
      'diagnosed': 'Diagnosed',
      'dosage': 'Dosage',
      'frequency': 'Frequency',
      'since': 'Since',
      'active': 'Active',
      'ongoing': 'Ongoing',
      'controlled': 'Controlled',
      'seasonal': 'Seasonal',
      'asNeeded': 'As needed',
      'severe': 'Severe',
      'mild': 'Mild',
      'allergen': 'Allergen',
      'reaction': 'Reaction',

      // Chatbot
      'assistantTitle': 'HealthSync Assistant',
      'typeMessage': 'Describe your symptoms...',
      'urgentWarning': 'Urgent: Call emergency services now',
      'welcomeMessage':
          'Hello! I\'m the HealthSync assistant. How can I help you today?',
      'emergencyResponse':
          'Based on your symptoms, this could be serious. Please refer to the emergency banner above.',
      'generalResponse': 'I understand. Can you tell me more?',

      // Toast Messages
      'success': 'Success!',
      'error': 'Error!',
      'info': 'Info',

      // Doctor/Patient Names (mock data)
      'drSarahJohnson': 'Dr. Sarah Johnson',
      'drAhmedHassan': 'Dr. Ahmed Hassan',
      'drSaraMohamed': 'Dr. Sara Mohamed',
      'drOmarAli': 'Dr. Omar Ali',
      'drFatimaYoussef': 'Dr. Fatima Youssef',

      // Appointments
      'appointmentDate': 'Tue, Dec 12 • 10:00 AM',
      'online': 'Online',
      'inPerson': 'In Person',
      'noData': 'No data available',
      'passwordResetSent': 'Password reset email sent! Check your inbox.',
    },
    'ar': {
      'appName': 'هيلث سينك',
      // Onboarding
      'getStarted': 'ابدأ الآن',
      'onboardingTitle': 'صحتك بين يديك',
      'onboardingSubtitle':
          'راقب علاماتك الحيوية، أدر سجلاتك، وتواصل مع الأطباء بسهولة.',

      // Auth
      'login': 'تسجيل الدخول',
      'createAccount': 'إنشاء حساب',
      'accessAccount': 'تفضل بالدخول إلى حسابك',
      'emailAddress': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'fullName': 'الاسم الكامل',
      'medicalLicense': 'رقم الترخيص الطبي',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'orLoginWith': 'أو سجل الدخول بواسطة',
      'or': 'أو',
      'continueWithGoogle': 'المتابعة مع جوجل',
      'processingLogin': 'جاري تسجيل الدخول...',
      'creatingAccount': 'جاري إنشاء الحساب...',
      'patient': 'مريض',
      'doctor': 'طبيب',
      'enterEmail': 'يرجى إدخال البريد الإلكتروني',
      'validEmail': 'يرجى إدخال بريد إلكتروني صحيح',
      'enterPassword': 'يرجى إدخال كلمة المرور',
      'passwordLength': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'passwordLength8': 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
      'confirmPasswordReq': 'يرجى تأكيد كلمة المرور',
      'passwordsNoMatch': 'كلمتا المرور غير متطابقتين',
      'enterName': 'يرجى إدخال الاسم الكامل',
      'enterLicense': 'يرجى إدخال رقم الترخيص',
      'resetPassword': 'استعادة كلمة المرور',
      'resetPasswordDesc':
          'أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.',
      'sendResetLink': 'إرسال رابط الاستعادة',

      // Dashboard
      'hello': 'مرحبًا',
      'dashboard': 'الرئيسية',
      'vitals': 'العلامات الحيوية',
      'assistant': 'المساعد',
      'profile': 'الملف الشخصي',
      'myProfile': 'ملفي الشخصي',
      'currentHealthStatus': 'الحالة الصحية الحالية',
      'normal': 'طبيعي',
      'warning': 'تحذير',
      'critical': 'حرج',
      'heartRate': 'نبض القلب',
      'bloodOxygen': 'الأكسجين',
      'bloodPressure': 'ضغط الدم',
      'nextFollowUp': 'الموعد القادم',
      'seeAll': 'عرض الكل',
      'vitalsComingSoon': 'سجل العلامات الحيوية (قريباً)',
      'view': 'عرض',

      // Doctor Dashboard
      'needAttention': 'تحتاج انتباه',
      'criticalAlert': 'تنبيه حرج',
      'patientsNeedAttention': 'مريض يحتاج اهتمامًا فوريًا',

      // Profile & Settings
      'settings': 'الإعدادات',
      'medicalHistory': 'السجل الطبي',
      'privacySecurity': 'الخصوصية والأمان',
      'helpSupport': 'المساعدة والدعم',
      'guestUser': 'مستخدم زائر',
      'noEmail': 'لا يوجد بريد إلكتروني',
      'notifications': 'الإشعارات',
      'notificationsDesc': 'تلقي التنبيهات والتذكيرات',
      'language': 'اللغة',
      'logout': 'تسجيل الخروج',
      'logoutConfirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      'cancel': 'إلغاء',
      'notificationsTitle': 'الإشعارات',
      'noNotifications': 'لا توجد إشعارات جديدة',
      'markAllRead': 'تحديد الكل كمقروء',
      'doctorChatTitle': 'محادثة مع د. سارة',
      'typeDoctorMessage': 'اكتب رسالتك...',
      'doctorResponse':
          'مرحباً! لقد استلمت رسالتك. سأتحقق من علاماتك الحيوية وأعود إليك قريباً.',
      'chat': 'محادثة',

      // Doctor screens
      'doctorDashboard': 'لوحة الطبيب',
      'myPatients': 'مرضاي',
      'totalPatients': 'إجمالي المرضى',
      'pendingMessages': 'رسائل معلقة',
      'todayAppointments': 'مواعيد اليوم',
      'recentPatients': 'المرضى الأخيرين',
      'searchPatients': 'ابحث عن مريض...',
      'viewPatient': 'عرض المريض',
      'sendMessage': 'إرسال رسالة',
      'patientDetails': 'تفاصيل المريض',
      'lastUpdate': 'آخر تحديث',
      'typePatientMessage': 'اكتب رسالة للمريض...',
      'vitalsHistory': 'سجل العلامات الحيوية',

      // Medical History
      'conditions': 'الحالات المرضية',
      'medications': 'الأدوية',
      'allergies': 'الحساسية',
      'procedures': 'العمليات',
      'diagnosed': 'تاريخ التشخيص',
      'dosage': 'الجرعة',
      'frequency': 'التكرار',
      'since': 'منذ',
      'active': 'نشط',
      'ongoing': 'مستمر',
      'controlled': 'تحت السيطرة',
      'seasonal': 'موسمي',
      'asNeeded': 'عند الحاجة',
      'severe': 'شديد',
      'mild': 'خفيف',
      'allergen': 'المادة المسببة',
      'reaction': 'رد الفعل',

      // Chatbot
      'assistantTitle': 'مساعد هيلث سينك',
      'typeMessage': 'اكتب أعراضك...',
      'urgentWarning': 'عاجل: اتصل بخدمات الطوارئ الآن',
      'welcomeMessage':
          'مرحباً! أنا مساعد هيلث سينك. كيف يمكنني مساعدتك اليوم؟',
      'emergencyResponse':
          'بناءً على أعراضك، قد يكون هذا خطيراً. يرجى الرجوع إلى لافتة الطوارئ أعلاه.',
      'generalResponse': 'أفهم ذلك. هل يمكنك إخباري بالمزيد؟',

      // Follow-ups
      'upcomingFollowUps': 'المواعيد القادمة',
      'noFollowUps': 'لا توجد مواعيد قادمة',

      // Toast Messages
      'success': 'تم بنجاح!',
      'error': 'خطأ!',
      'info': 'معلومة',

      // Doctor/Patient Names (mock data)
      'drSarahJohnson': 'د. سارة جونسون',
      'drAhmedHassan': 'د. أحمد حسن',
      'drSaraMohamed': 'د. سارة محمد',
      'drOmarAli': 'د. عمر علي',
      'drFatimaYoussef': 'د. فاطمة يوسف',

      // Appointments
      'appointmentDate': 'الثلاثاء، 12 ديسمبر • 10:00 ص',
      'online': 'عن بُعد',
      'inPerson': 'حضوري',
      'noData': 'لا توجد بيانات',
      'passwordResetSent': 'تم إرسال رابط استعادة كلمة المرور! تحقق من بريدك.',
    },
  };

  /// Get a localized string. Falls back to Google Translate if key is not found.
  String get(String key) {
    final langCode = locale.languageCode;

    // First check predefined translations
    if (_localizedValues[langCode]?.containsKey(key) == true) {
      return _localizedValues[langCode]![key]!;
    }

    // Check cache
    if (_translationCache[langCode]?.containsKey(key) == true) {
      return _translationCache[langCode]![key]!;
    }

    // Return key if not found (will be auto-translated async)
    return key;
  }

  /// Async get with auto-translation fallback
  Future<String> getAsync(String key) async {
    final langCode = locale.languageCode;

    // First check predefined translations
    if (_localizedValues[langCode]?.containsKey(key) == true) {
      return _localizedValues[langCode]![key]!;
    }

    // Check cache
    if (_translationCache[langCode]?.containsKey(key) == true) {
      return _translationCache[langCode]![key]!;
    }

    // If we have English version and need Arabic, translate it
    if (langCode == 'ar' && _localizedValues['en']?.containsKey(key) == true) {
      final englishText = _localizedValues['en']![key]!;
      final translated = await TranslationService.translate(englishText);
      _translationCache['ar']![key] = translated;
      return translated;
    }

    return key;
  }

  /// Translate any text on-the-fly
  Future<String> translate(String text) async {
    if (locale.languageCode == 'en') return text;
    return TranslationService.translate(text, to: locale.languageCode);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
