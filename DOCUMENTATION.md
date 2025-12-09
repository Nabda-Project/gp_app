# HealthSync - Flutter Medical App Documentation

## 📱 Overview
HealthSync is a Flutter-based medical application that allows patients to monitor their health, chat with doctors, and manage medical appointments. The app supports **Arabic and English** localization.

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── user_model.dart          # User data (name, email, role)
│   ├── measurement_model.dart   # Health measurements
│   └── settings_model.dart      # App settings (language, notifications)
├── routes/
│   └── app_routes.dart          # Navigation routes
├── screens/                     # UI Screens
│   ├── splash/                  # Splash screen
│   ├── onboarding/              # Welcome/onboarding screen
│   ├── auth/                    # Login/Register screen
│   ├── patient/                 # Patient-specific screens
│   │   ├── patient_dashboard_screen.dart
│   │   ├── chatbot_screen.dart      # AI Assistant
│   │   ├── doctor_chat_screen.dart  # Chat with Doctor
│   │   └── follow_ups_screen.dart   # Appointments list
│   ├── profile/                 # User profile
│   ├── settings/                # App settings
│   └── notifications/           # Notifications screen
├── services/
│   └── storage_service.dart     # Local storage (Hive)
├── theme/
│   └── app_theme.dart           # App-wide theme
├── utils/
│   ├── constants.dart           # Colors, dimensions, strings
│   └── app_localizations.dart   # Translations (EN/AR)
└── widgets/reusable/            # Reusable UI components
    ├── custom_button.dart       # Gradient button
    ├── vital_card.dart          # Health metrics card
    ├── status_card.dart         # Health status indicator
    ├── decorated_background.dart # Background decorations
    └── ...
```

---

## 🔑 Key Files Explained

### 1. `main.dart` - App Entry Point
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();  // Initialize Hive storage
  runApp(const MyApp());
}
```
- Initializes Flutter bindings
- Sets up Hive local storage
- Runs the app with `MyApp` widget

### 2. `models/user_model.dart` - User Data
```dart
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;  // 'Patient' or 'Doctor'
  final String? licenseNumber;
}
```
- Stores user information
- Persisted to Hive for offline access

### 3. `services/storage_service.dart` - Local Storage
```dart
class StorageService {
  static Future<void> saveUser(UserModel user);  // Save user
  static UserModel? getUser();                    // Get current user
  static bool get isLoggedIn;                     // Check login status
  static Future<void> logout();                   // Clear user data
  static Future<void> saveSettings(SettingsModel);
  static SettingsModel getSettings();
}
```
- Uses **Hive** for local data persistence
- Stores: User, Settings, Measurements

### 4. `routes/app_routes.dart` - Navigation
```dart
static const String splash = '/';
static const String onboarding = '/onboarding';
static const String auth = '/auth';
static const String patientDashboard = '/patient_dashboard';
static const String chatbot = '/chatbot';
static const String doctorChat = '/doctor_chat';
static const String followUps = '/follow_ups';
static const String profile = '/profile';
static const String settings = '/settings';
static const String notifications = '/notifications';
```
- Defines all app routes
- Maps route strings to screen widgets

### 5. `utils/app_localizations.dart` - Translations
```dart
// English
'heartRate': 'Heart Rate',
'bloodOxygen': 'Blood Oxygen',

// Arabic
'heartRate': 'معدل ضربات القلب',
'bloodOxygen': 'أكسجين الدم',
```
- Contains all UI strings in English and Arabic
- Access via: `AppLocalizations.of(context)!.get('key')`

### 6. `utils/constants.dart` - Design Tokens
```dart
class AppColors {
  static const Color primaryBlue = Color(0xFF407BFF);
  static const Color darkBlue = Color(0xFF03045E);
  static const Color grey = Color(0xFF94A3B8);
  static const LinearGradient primaryGradient = ...;
}

class AppDimensions {
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double radiusM = 16.0;
}
```
- Centralized colors, padding, and dimensions
- Ensures consistent design

---

## 📱 Screens Overview

### Splash Screen (`splash_screen.dart`)
- Gradient background with logo
- Auto-navigates to Dashboard (if logged in) or Onboarding

### Onboarding Screen (`onboarding_screen.dart`)
- Welcome screen with app description
- "Get Started" button → Auth Screen

### Auth Screen (`auth_screen.dart`)
- Login and Register tabs
- Role selection: Patient or Doctor
- Saves user data to Hive on success

### Patient Dashboard (`patient_dashboard_screen.dart`)
- **Bottom Navigation**: Dashboard, Chat, Profile
- **FAB**: AI Assistant (robot icon)
- **Widgets**:
  - Health Status Card
  - Vital Cards (Heart Rate, Blood Oxygen, etc.)
  - Next Follow-up Card

### Chatbot Screen (`chatbot_screen.dart`)
- AI Health Assistant
- Type symptoms → Get AI responses
- Emergency banner for critical symptoms

### Doctor Chat Screen (`doctor_chat_screen.dart`)
- Chat interface with assigned doctor
- Message bubbles UI

### Follow-ups Screen (`follow_ups_screen.dart`)
- List of upcoming appointments
- Doctor info, date/time
- Quick message button

### Profile Screen (`profile_screen.dart`)
- User info card (name, email, role)
- Settings, Medical History options
- Logout button

### Settings Screen (`settings_screen.dart`)
- Enable/disable notifications toggle
- Language selector (English/Arabic)

### Notifications Screen (`notifications_screen.dart`)
- List of notifications
- "Mark all as read" action

---

## 🧩 Reusable Widgets

### `VitalCard`
```dart
VitalCard(
  label: 'Heart Rate',
  value: '72',
  unit: 'bpm',
  icon: Icons.favorite,
  color: Colors.redAccent,
)
```
Displays a health metric with icon, value, and label.

### `StatusCard`
```dart
StatusCard(
  title: 'Current Health Status',
  status: 'Normal',
  isHealthy: true,
)
```
Shows health status with color-coded indicator.

### `CustomButton`
```dart
CustomButton(
  text: 'Get Started',
  onPressed: () => Navigator.pushNamed(...),
  useGradient: true,  // Gradient background
)
```
Primary action button with gradient and glow.

### `DecoratedBackground`
```dart
DecoratedBackground(
  child: YourContent(),
)
```
Adds subtle decorative circles to screen backgrounds.

---

## 🗄️ Data Flow

```
User Input → Screen Widget → StorageService → Hive Box
                ↓
            UI Updates ← State Management (setState)
```

1. User enters data (login, settings)
2. Screen calls `StorageService.saveXxx()`
3. Data saved to Hive box
4. On app restart, data loaded from Hive

---

## 🌐 Localization

To change language:
1. Go to **Profile → Settings**
2. Select language from dropdown
3. App rebuilds with new locale

To add new strings:
1. Open `lib/utils/app_localizations.dart`
2. Add key-value in `'en'` map
3. Add same key with Arabic translation in `'ar'` map

---

## 📦 Dependencies

```yaml
dependencies:
  flutter: sdk
  hive: ^2.2.3           # Local storage
  hive_flutter: ^1.1.0
  intl: ^0.19.0          # Date formatting
  font_awesome_flutter: ^10.6.0  # Icons
  flutter_localizations: sdk
```

---

## 🏗️ Build Commands

```bash
# Run in debug mode
flutter run

# Build APK (release)
flutter build apk --release

# APK location
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📝 Adding New Features

### Add a new screen:
1. Create file in `lib/screens/[category]/`
2. Add route in `lib/routes/app_routes.dart`
3. Navigate: `Navigator.pushNamed(context, '/route_name')`

### Add a new widget:
1. Create file in `lib/widgets/reusable/`
2. Import and use in screens

### Add localization strings:
1. Edit `lib/utils/app_localizations.dart`
2. Add to both `'en'` and `'ar'` maps
