# HealthSync

**HealthSync** is a modern, connected healthcare application built with Flutter, designed to bridge the gap between patients and healthcare providers. It features distinct portals for patients and doctors, enabling real-time vitals monitoring, secure communication, and efficient medical history management.

## 🌟 Features

### 🏥 Patient Portal
- **Dashboard**: At-a-glance view of current health status, vitals, and upcoming events.
- **Vitals Monitoring**: Track and visualize Heart Rate, Blood Pressure, and Blood Oxygen levels.
- **Medical History**: Comprehensive digital record of Conditions, Medications, Allergies, and Procedures.
- **AI Health Assistant**: Intelligent chatbot for immediate health queries and symptom assessment.
- **Doctor Communication**: Secure messaging channel with assigned doctors.
- **Appointment Management**: View details of next follow-up visits.

### 👨‍⚕️ Doctor Portal
- **Overview Dashboard**: Quick stats on Admitted Patients and Critical Alerts.
- **Patient Management**: Searchable list of patients with detailed profiles.
- **Critical Alerts**: Real-time identification of patients requiring urgent attention.
- **Detailed Analytics**: View history and trends for individual patients.

### 🔐 Core Features
- **Secure Authentication**: Robust Sign-Up/Login using Firebase Auth (Email/Password & Google).
- **Role-Based Access Control**: Distinct flows and permissions for Doctors and Patients.
- **Modern UI/UX**: Polished, animated interface with "Hero" transitions and glassmorphism elements.
- **Localization**: Built-in support structure for multiple languages.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend**: [Firebase](https://firebase.google.com/)
    - **Authentication**: User management and secure login.
    - **Cloud Firestore**: Real-time NoSQL database for syncing user data and chats.
- **Local Storage**: [Hive](https://docs.hivedb.dev/) for efficient local data persistence.
- **State Management**: Clean architecture utilizing `StatefulWidget` and Services.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- access to a Firebase project (configured in `firebase_options.dart`).

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Gp-team26/gp_app
    cd gp_app
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the App**:
    ```bash
    flutter run
    ```
    *Note: Ensure you have an emulator running or a device connected.*

## 📂 Project Structure

```
lib/
├── models/         # Data models (UserModel, etc.)
├── screens/        # UI Screens grouped by feature
│   ├── auth/       # Login, Register
│   ├── doctor/     # Doctor Dashboard & Details
│   ├── patient/    # Patient Dashboard, History, Chat
│   ├── splash/     # App Entry & Animations
│   └── ...
├── services/       # Business Logic (Auth, Firestore, Storage)
├── utils/          # Constants, styles, and helpers
└── widgets/        # Reusable UI components
    ├── animations/ # Custom animations (Fade, Slide, etc.)
    └── reusable/   # Cards, Buttons, Inputs
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
