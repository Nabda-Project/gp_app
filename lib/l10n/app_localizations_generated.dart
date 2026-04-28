import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_generated_ar.dart';
import 'app_localizations_generated_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of GeneratedLocalizations
/// returned by `GeneratedLocalizations.of(context)`.
///
/// Applications need to include `GeneratedLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations_generated.dart';
///
/// return MaterialApp(
///   localizationsDelegates: GeneratedLocalizations.localizationsDelegates,
///   supportedLocales: GeneratedLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the GeneratedLocalizations.supportedLocales
/// property.
abstract class GeneratedLocalizations {
  GeneratedLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static GeneratedLocalizations? of(BuildContext context) {
    return Localizations.of<GeneratedLocalizations>(
      context,
      GeneratedLocalizations,
    );
  }

  static const LocalizationsDelegate<GeneratedLocalizations> delegate =
      _GeneratedLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HealthSync'**
  String get appName;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Health, Your Hands'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor your vitals, manage your records, and connect with doctors easily.'**
  String get onboardingSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @accessAccount.
  ///
  /// In en, this message translates to:
  /// **'Access your HealthSync account'**
  String get accessAccount;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @medicalLicense.
  ///
  /// In en, this message translates to:
  /// **'Medical License Number'**
  String get medicalLicense;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @orLoginWith.
  ///
  /// In en, this message translates to:
  /// **'Or login with'**
  String get orLoginWith;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @processingLogin.
  ///
  /// In en, this message translates to:
  /// **'Processing Login...'**
  String get processingLogin;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating Account...'**
  String get creatingAccount;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterEmail;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @passwordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLength;

  /// No description provided for @passwordLength8.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordLength8;

  /// No description provided for @confirmPasswordReq.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordReq;

  /// No description provided for @passwordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsNoMatch;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get enterName;

  /// No description provided for @enterLicense.
  ///
  /// In en, this message translates to:
  /// **'Please enter license number'**
  String get enterLicense;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get enterPhone;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @selectDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get selectDateOfBirth;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get selectGender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get resetPasswordDesc;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @vitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitals;

  /// No description provided for @assistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get assistant;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @currentHealthStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Health Status'**
  String get currentHealthStatus;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRate;

  /// No description provided for @bloodOxygen.
  ///
  /// In en, this message translates to:
  /// **'Blood Oxygen'**
  String get bloodOxygen;

  /// No description provided for @bloodPressure.
  ///
  /// In en, this message translates to:
  /// **'BP (Est)'**
  String get bloodPressure;

  /// No description provided for @nextFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Next Follow-up'**
  String get nextFollowUp;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @vitalsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Vitals History (Coming Soon)'**
  String get vitalsComingSoon;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @needAttention.
  ///
  /// In en, this message translates to:
  /// **'Need Attention'**
  String get needAttention;

  /// No description provided for @criticalAlert.
  ///
  /// In en, this message translates to:
  /// **'Critical Alert'**
  String get criticalAlert;

  /// No description provided for @patientsNeedAttention.
  ///
  /// In en, this message translates to:
  /// **'patient(s) need immediate attention'**
  String get patientsNeedAttention;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistory;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts and reminders'**
  String get notificationsDesc;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @doctorChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with Dr. Sarah'**
  String get doctorChatTitle;

  /// No description provided for @typeDoctorMessage.
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get typeDoctorMessage;

  /// No description provided for @doctorResponse.
  ///
  /// In en, this message translates to:
  /// **'Hello! I received your message. I will check your vitals and get back to you shortly.'**
  String get doctorResponse;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @doctorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Doctor Dashboard'**
  String get doctorDashboard;

  /// No description provided for @myPatients.
  ///
  /// In en, this message translates to:
  /// **'My Patients'**
  String get myPatients;

  /// No description provided for @totalPatients.
  ///
  /// In en, this message translates to:
  /// **'Total Patients'**
  String get totalPatients;

  /// No description provided for @pendingMessages.
  ///
  /// In en, this message translates to:
  /// **'Pending Messages'**
  String get pendingMessages;

  /// No description provided for @todayAppointments.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Appointments'**
  String get todayAppointments;

  /// No description provided for @recentPatients.
  ///
  /// In en, this message translates to:
  /// **'Recent Patients'**
  String get recentPatients;

  /// No description provided for @searchPatients.
  ///
  /// In en, this message translates to:
  /// **'Search patients...'**
  String get searchPatients;

  /// No description provided for @viewPatient.
  ///
  /// In en, this message translates to:
  /// **'View Patient'**
  String get viewPatient;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @patientDetails.
  ///
  /// In en, this message translates to:
  /// **'Patient Details'**
  String get patientDetails;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdate;

  /// No description provided for @typePatientMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message to patient...'**
  String get typePatientMessage;

  /// No description provided for @vitalsHistory.
  ///
  /// In en, this message translates to:
  /// **'Vitals History'**
  String get vitalsHistory;

  /// No description provided for @assignPatient.
  ///
  /// In en, this message translates to:
  /// **'Assign Patient'**
  String get assignPatient;

  /// No description provided for @searchByNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone number...'**
  String get searchByNameOrPhone;

  /// No description provided for @searchByNameLabel.
  ///
  /// In en, this message translates to:
  /// **'By Name'**
  String get searchByNameLabel;

  /// No description provided for @searchByPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'By Phone'**
  String get searchByPhoneLabel;

  /// No description provided for @searchByNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter patient name...'**
  String get searchByNameHint;

  /// No description provided for @searchByPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number...'**
  String get searchByPhoneHint;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No patients found'**
  String get noResults;

  /// No description provided for @patientAssigned.
  ///
  /// In en, this message translates to:
  /// **'Patient assigned successfully!'**
  String get patientAssigned;

  /// No description provided for @alreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Patient is already assigned to you'**
  String get alreadyAssigned;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet and try again.'**
  String get connectionError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unexpectedError;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type a name or phone number to search'**
  String get typeToSearch;

  /// No description provided for @removePatient.
  ///
  /// In en, this message translates to:
  /// **'Remove Patient'**
  String get removePatient;

  /// No description provided for @removePatientConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this patient from your list?'**
  String get removePatientConfirm;

  /// No description provided for @removePatientSuccess.
  ///
  /// In en, this message translates to:
  /// **'Patient removed successfully'**
  String get removePatientSuccess;

  /// No description provided for @removePatientError.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove patient. Please try again.'**
  String get removePatientError;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @conditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get conditions;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @procedures.
  ///
  /// In en, this message translates to:
  /// **'Procedures'**
  String get procedures;

  /// No description provided for @diagnosed.
  ///
  /// In en, this message translates to:
  /// **'Diagnosed'**
  String get diagnosed;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get since;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @controlled.
  ///
  /// In en, this message translates to:
  /// **'Controlled'**
  String get controlled;

  /// No description provided for @seasonal.
  ///
  /// In en, this message translates to:
  /// **'Seasonal'**
  String get seasonal;

  /// No description provided for @asNeeded.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get asNeeded;

  /// No description provided for @severe.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severe;

  /// No description provided for @mild.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get mild;

  /// No description provided for @allergen.
  ///
  /// In en, this message translates to:
  /// **'Allergen'**
  String get allergen;

  /// No description provided for @reaction.
  ///
  /// In en, this message translates to:
  /// **'Reaction'**
  String get reaction;

  /// No description provided for @assistantTitle.
  ///
  /// In en, this message translates to:
  /// **'HealthSync Assistant'**
  String get assistantTitle;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Describe your symptoms...'**
  String get typeMessage;

  /// No description provided for @urgentWarning.
  ///
  /// In en, this message translates to:
  /// **'Urgent: Call emergency services now'**
  String get urgentWarning;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m the HealthSync assistant. How can I help you today?'**
  String get welcomeMessage;

  /// No description provided for @emergencyResponse.
  ///
  /// In en, this message translates to:
  /// **'Based on your symptoms, this could be serious. Please refer to the emergency banner above.'**
  String get emergencyResponse;

  /// No description provided for @generalResponse.
  ///
  /// In en, this message translates to:
  /// **'I understand. Can you tell me more?'**
  String get generalResponse;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error!'**
  String get error;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @drSarahJohnson.
  ///
  /// In en, this message translates to:
  /// **'Dr. Sarah Johnson'**
  String get drSarahJohnson;

  /// No description provided for @drAhmedHassan.
  ///
  /// In en, this message translates to:
  /// **'Dr. Ahmed Hassan'**
  String get drAhmedHassan;

  /// No description provided for @drSaraMohamed.
  ///
  /// In en, this message translates to:
  /// **'Dr. Sara Mohamed'**
  String get drSaraMohamed;

  /// No description provided for @drOmarAli.
  ///
  /// In en, this message translates to:
  /// **'Dr. Omar Ali'**
  String get drOmarAli;

  /// No description provided for @drFatimaYoussef.
  ///
  /// In en, this message translates to:
  /// **'Dr. Fatima Youssef'**
  String get drFatimaYoussef;

  /// No description provided for @appointmentDate.
  ///
  /// In en, this message translates to:
  /// **'Tue, Dec 12 • 10:00 AM'**
  String get appointmentDate;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @inPerson.
  ///
  /// In en, this message translates to:
  /// **'In Person'**
  String get inPerson;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Check your inbox.'**
  String get passwordResetSent;

  /// No description provided for @missedAppointments.
  ///
  /// In en, this message translates to:
  /// **'Missed Appointments'**
  String get missedAppointments;

  /// No description provided for @upcomingFollowUps.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Follow-ups'**
  String get upcomingFollowUps;

  /// No description provided for @noFollowUps.
  ///
  /// In en, this message translates to:
  /// **'No upcoming follow-ups'**
  String get noFollowUps;

  /// No description provided for @batteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Battery Level'**
  String get batteryLevel;

  /// No description provided for @yourDoctor.
  ///
  /// In en, this message translates to:
  /// **'Your Doctor'**
  String get yourDoctor;

  /// No description provided for @noDoctorAssigned.
  ///
  /// In en, this message translates to:
  /// **'No doctor assigned yet'**
  String get noDoctorAssigned;

  /// No description provided for @noDoctorAssignedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your care team will be shown here once assigned.'**
  String get noDoctorAssignedDesc;

  /// No description provided for @noPatientsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No patients assigned yet.'**
  String get noPatientsAssigned;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.\nStart chatting from the Patients tab!'**
  String get noConversations;

  /// No description provided for @appointmentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Appointment Confirmed'**
  String get appointmentConfirmed;

  /// No description provided for @appointmentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Appointment Cancelled'**
  String get appointmentCancelled;

  /// No description provided for @appointmentCompleted.
  ///
  /// In en, this message translates to:
  /// **'Appointment Completed'**
  String get appointmentCompleted;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @newAppointment.
  ///
  /// In en, this message translates to:
  /// **'New Appointment'**
  String get newAppointment;

  /// No description provided for @appointmentScheduledNotif.
  ///
  /// In en, this message translates to:
  /// **'You have a new appointment scheduled'**
  String get appointmentScheduledNotif;

  /// No description provided for @appointmentConfirmedNotif.
  ///
  /// In en, this message translates to:
  /// **'Your appointment has been confirmed'**
  String get appointmentConfirmedNotif;

  /// No description provided for @appointmentCancelledNotif.
  ///
  /// In en, this message translates to:
  /// **'Your appointment has been cancelled'**
  String get appointmentCancelledNotif;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete Notification'**
  String get deleteNotification;

  /// No description provided for @deleteNotificationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this notification?'**
  String get deleteNotificationConfirm;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @enterHeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter your height'**
  String get enterHeight;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @enterWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter your weight'**
  String get enterWeight;

  /// No description provided for @chooseAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose your account type'**
  String get chooseAccountType;

  /// No description provided for @continueAsDoctor.
  ///
  /// In en, this message translates to:
  /// **'Continue as Doctor'**
  String get continueAsDoctor;

  /// No description provided for @continueAsPatient.
  ///
  /// In en, this message translates to:
  /// **'Continue as Patient'**
  String get continueAsPatient;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @healthInfo.
  ///
  /// In en, this message translates to:
  /// **'Health Information'**
  String get healthInfo;

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePicture;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;
}

class _GeneratedLocalizationsDelegate
    extends LocalizationsDelegate<GeneratedLocalizations> {
  const _GeneratedLocalizationsDelegate();

  @override
  Future<GeneratedLocalizations> load(Locale locale) {
    return SynchronousFuture<GeneratedLocalizations>(
      lookupGeneratedLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_GeneratedLocalizationsDelegate old) => false;
}

GeneratedLocalizations lookupGeneratedLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return GeneratedLocalizationsAr();
    case 'en':
      return GeneratedLocalizationsEn();
  }

  throw FlutterError(
    'GeneratedLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
