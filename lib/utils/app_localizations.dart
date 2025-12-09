import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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

      // Dashboard
      'hello': 'Hello',
      'dashboard': 'Dashboard',
      'vitals': 'Vitals',
      'assistant': 'Assistant',
      'profile': 'Profile',
      'myProfile': 'My Profile',
      'currentHealthStatus': 'Current Health Status',
      'normal': 'Normal',
      'heartRate': 'Heart Rate',
      'bloodOxygen': 'Blood Oxygen',
      'bloodPressure': 'BP (Est)',
      'nextFollowUp': 'Next Follow-up',
      'seeAll': 'See All',
      'vitalsComingSoon': 'Vitals History (Coming Soon)',

      // Profile & Settings
      'settings': 'Settings',
      'medicalHistory': 'Medical History',
      'privacySecurity': 'Privacy & Security',
      'helpSupport': 'Help & Support',
      'guestUser': 'Guest User',
      'noEmail': 'No Email',
      'notifications': 'Notifications',
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

      // Chatbots and reminders
    },
    'ar': {
      'appName': 'هالـث سينك',
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

      // Dashboard
      'hello': 'مرحبًا',
      'dashboard': 'الرئيسية',
      'vitals': 'العلامات الحيوية',
      'assistant': 'المساعد',
      'profile': 'الملف الشخصي',
      'myProfile': 'ملفي الشخصي',
      'currentHealthStatus': 'الحالة الصحية الحالية',
      'normal': 'طبيعي',
      'heartRate': 'نبض القلب',
      'bloodOxygen': 'الأكسجين',
      'bloodPressure': 'ضغط الدم',
      'nextFollowUp': 'الموعد القادم',
      'seeAll': 'عرض الكل',
      'vitalsComingSoon': 'سجل العلامات الحيوية (قريباً)',

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

      // Chatbot
      'assistantTitle': 'مساعد هيلث سينك',
      'typeMessage': 'اكتب أعراضك...',
      'urgentWarning': 'عاجل: اتصل بخدمات الطوارئ الآن',
      'welcomeMessage':
          'مرحباً! أنا مساعد هيلث سينك. كيف يمكنني مساعدتك اليوم؟',
      'emergencyResponse':
          'بناءً على أعراضك، قد يكون هذا خطيراً. يرجى الرجوع إلى لافتة الطوارئ أعلاه.',
      'generalResponse': 'أفهم ذلك. هل يمكنك إخباري بالمزيد؟',

      // Vitals History
      'vitalsHistory': 'سجل العلامات الحيوية',
      'noVitalsData': 'لا توجد بيانات للعلامات الحيوية.',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
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
