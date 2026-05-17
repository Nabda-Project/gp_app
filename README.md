# NABDA

**NABDA** is a connected healthcare follow-up and diagnostic support system designed to improve communication between patients and doctors, support continuous monitoring, and assist doctors with structured patient data.

The system combines a Flutter mobile application, backend APIs, real-time communication, wearable device readings, notifications, and AI-assisted cardiac assessment. NABDA focuses mainly on cardiovascular monitoring and follow-up, where patients can monitor vital signs, complete medical assessments, communicate with doctors, and receive alerts, while doctors can supervise assigned patients, review critical cases, and follow up efficiently.

> **Medical Disclaimer:** NABDA is a healthcare support system. It does not replace doctors, provide final diagnosis, or make treatment decisions. Final medical decisions must always be made by qualified healthcare professionals.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Problem Statement](#problem-statement)
- [Project Objectives](#project-objectives)
- [System Users](#system-users)
- [Main Features](#main-features)
- [Patient Portal](#patient-portal)
- [Doctor Portal](#doctor-portal)
- [AI Cardiac Assessment](#ai-cardiac-assessment)
- [Health Monitoring](#health-monitoring)
- [Notifications and Alerts](#notifications-and-alerts)
- [Real-Time Chat](#real-time-chat)
- [System Architecture](#system-architecture)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Main Mobile Modules](#main-mobile-modules)
- [Backend Integration](#backend-integration)
- [Wearable Device Integration](#wearable-device-integration)
- [Authentication and Authorization](#authentication-and-authorization)
- [Localization](#localization)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Environment Configuration](#environment-configuration)
- [Android Permissions](#android-permissions)
- [Testing](#testing)
- [Current Limitations](#current-limitations)
- [Future Work](#future-work)
- [Medical Safety Disclaimer](#medical-safety-disclaimer)
- [Team](#team)
- [Supervisor](#supervisor)
- [License](#license)

---

## Project Overview

NABDA is a graduation project that aims to build an intelligent diagnostic support and follow-up system. The system is designed around two main roles:

1. **Patient**
2. **Doctor**

Patients can use the mobile app to monitor their health status, view vital signs, complete cardiac assessments, chat with their assigned doctor, and manage their profile.

Doctors can use the app to view assigned patients, monitor patient status, receive critical alerts, open patient details, review reports, and communicate with patients.

The project is built with scalability in mind. The current focus is cardiovascular monitoring and follow-up, but the system can be extended later to support more medical specialties.

---

## Problem Statement

Healthcare systems often suffer from long waiting times, weak follow-up, incomplete patient history, and repeated manual data collection during consultations. Doctors may spend a large part of consultation time asking routine history-taking questions instead of focusing on medical decisions.

Patients also may not receive continuous monitoring after leaving the clinic or hospital. Dangerous changes in vital signs may not be noticed early enough, and follow-up appointments may depend on manual scheduling and patient memory.

NABDA addresses these issues by providing:

- Digital patient history collection.
- Continuous health monitoring.
- Doctor-facing patient supervision.
- Critical alerts.
- Patient-doctor communication.
- AI-assisted structured assessment.
- Centralized patient data access.

---

## Project Objectives

The main objectives of NABDA are:

- Build a mobile application for both patients and doctors.
- Enable role-based access for patient and doctor workflows.
- Allow patients to monitor vital signs.
- Connect the mobile app with wearable readings.
- Provide doctor dashboards for patient supervision.
- Support real-time communication between patients and doctors.
- Provide structured AI-assisted cardiac assessment.
- Store and display medical history and reports.
- Alert doctors when dangerous readings are detected.
- Improve follow-up and reduce repeated manual data collection.

---

## System Users

### Patient

The patient uses the mobile application to:

- View health status.
- Monitor vital readings.
- View assigned doctor.
- Chat with doctor.
- Complete AI cardiac assessment.
- View report history.
- Receive notifications.
- Manage profile and settings.

### Doctor

The doctor uses the mobile application to:

- View dashboard overview.
- Track assigned patients.
- Search and assign patients.
- Review patient details.
- Monitor critical patient states.
- View patient reports.
- Chat with patients.
- Receive notifications and alerts.

---

## Main Features

### Core Features

- Role-based patient and doctor portals.
- Firebase authentication.
- Backend JWT authentication.
- Patient dashboard.
- Doctor dashboard.
- Wearable data monitoring.
- Background health monitoring service.
- Critical alerts.
- Real-time chat.
- AI cardiac assessment.
- Report history.
- Notifications.
- Profile management.
- Localization support.
- Reusable UI components.
- REST API integration.
- WebSocket/STOMP integration.

---

## Patient Portal

The patient portal provides a simple and focused experience for patients. It allows patients to track their own health data and communicate with their assigned doctor.

### Patient Dashboard

The patient dashboard displays:

- Patient greeting.
- Current health status.
- Latest vital readings.
- Assigned doctor card.
- Next follow-up information.
- Notifications access.
- Chat access.
- AI assessment entry point.

### Patient Vitals

Patients can view:

- Heart rate readings.
- Oxygen-related readings.
- Battery or device status.
- Live readings from the wearable device.
- Historical vital readings.
- Trend charts and summaries.

### Patient Profile

Patients can manage personal and health-related data such as:

- Full name.
- Email.
- Phone number.
- Date of birth.
- Gender.
- Height.
- Weight.
- Profile image.

### Patient Notifications

Patients can receive and view notifications related to:

- Health updates.
- Appointments.
- Doctor messages.
- System alerts.

---

## Doctor Portal

The doctor portal is designed to support supervision and follow-up. It gives doctors an overview of assigned patients and highlights critical cases.

### Doctor Dashboard

The doctor dashboard displays:

- Total assigned patients.
- Critical or warning cases.
- Recent patients.
- Appointment-related information.
- Chat and notification shortcuts.
- Critical patient alerts.

### Patient Management

Doctors can:

- View assigned patients.
- Search patients.
- Assign a patient.
- Remove assigned patients.
- Open patient details.
- Start a chat with a patient.

### Patient Details

The patient details screen allows doctors to review:

- Patient personal information.
- Latest vitals.
- Health status.
- Follow-up actions.
- Chat shortcut.
- AI report history.
- Critical indicators.

### Critical Alerts

Doctors can see critical patient states through:

- Dashboard alert cards.
- Highlighted patient status.
- Notification list.
- Patient detail status.

---

## AI Cardiac Assessment

NABDA includes a structured AI-assisted cardiac assessment module. This module is not a free-text chatbot only; it uses a controlled multi-step flow to collect patient data in a consistent format.

### Assessment Flow

The assessment collects:

1. Medical history.
2. Symptoms.
3. Symptom-specific details.
4. Red-flag answers.
5. Optional free-text notes.
6. Final review before submission.

### AI Report

After submission, the app displays an AI-assisted report that may include:

- Patient summary.
- Symptom summary.
- Risk-related observations.
- Suggested follow-up direction.
- Advisory disclaimer.

### Report History

Patients can view previous assessment reports from the report history screen.

> AI reports are advisory only and must be reviewed by qualified medical professionals.

---

## Health Monitoring

NABDA supports health monitoring through a foreground background service on Android.

### HealthMonitorService

The mobile application includes a background monitoring service responsible for:

- Starting and stopping monitoring.
- Listening for wearable data packets.
- Parsing incoming readings.
- Validating readings.
- Updating the patient dashboard.
- Uploading readings to the backend.
- Triggering local alerts based on thresholds.
- Handling disconnected device states.

### Monitoring Flow

The general monitoring flow is:

1. Wearable device sends readings.
2. Mobile app receives readings through UDP.
3. Background service parses the packet.
4. App validates the reading.
5. UI updates with the latest values.
6. Reading is uploaded to backend.
7. Alert thresholds are checked.
8. Doctor dashboard and notifications reflect critical cases.

---

## Notifications and Alerts

NABDA supports both backend-driven notifications and local critical alerts.

### Notification Types

- Patient notifications.
- Doctor notifications.
- Chat-related notifications.
- Critical vital alerts.
- Appointment-related notifications.

### Notification Sources

- Firebase Cloud Messaging.
- Backend notification API.
- Local notifications from background monitoring service.

### Critical Alerts

Critical alerts may be triggered by abnormal readings such as:

- Very high heart rate.
- Very low heart rate.
- Low oxygen-related values.
- Device disconnection or missing readings.

The exact thresholds can be adjusted according to backend and clinical requirements.

---

## Real-Time Chat

NABDA includes real-time patient-doctor messaging.

### Chat Features

- Patient-to-doctor chat.
- Doctor-to-patient chat.
- Conversation list.
- Message history.
- Real-time message updates.
- Presence or online status support.
- Message status updates.

### Communication Layer

The chat module uses:

- REST APIs for loading history and conversations.
- WebSocket/STOMP for real-time messages and updates.

---

## System Architecture

The system is divided into multiple layers:

### Mobile Application Layer

Built with Flutter and responsible for:

- User interface.
- Navigation.
- Authentication flow.
- Patient and doctor portals.
- Local storage.
- Notifications.
- Chat UI.
- Health monitoring UI.
- AI assessment UI.

### Service Layer

Responsible for:

- API calls.
- Token handling.
- Authentication services.
- Chat service.
- Notification service.
- IoT service.
- Health monitoring service.
- User profile service.
- Appointment service.
- AI assessment service.

### Backend Layer

Responsible for:

- Authentication integration.
- User management.
- Patient-doctor assignment.
- Vitals storage.
- Notification management.
- AI assessment report handling.
- Chat history.
- Critical state processing.

### Wearable Layer

Responsible for:

- Capturing vital signs.
- Sending readings to the mobile app.
- Supporting real-time monitoring.

---

## Tech Stack

### Mobile Application

- Flutter
- Dart

### Authentication

- Firebase Authentication
- Backend JWT authentication

### Backend Communication

- Spring Boot REST APIs
- Dio HTTP client
- JWT bearer tokens

### Real-Time Communication

- WebSocket
- STOMP
- REST APIs for history loading

### Notifications

- Firebase Cloud Messaging
- Flutter Local Notifications
- Android notification channels

### Local Storage

- Hive
- SharedPreferences
- Flutter Secure Storage

### Monitoring

- Flutter Background Service
- Android Foreground Service
- UDP Socket Listener
- Wearable device packet parsing

### UI and UX

- Reusable widgets
- Animated cards
- Bottom navigation
- Loading skeletons
- Status cards
- Profile avatars
- Localization support

---

## Project Structure

```text
lib/
|-- main.dart
|-- core/
|   |-- api/
|   |-- config/
|-- features/
|   |-- ai_assessment/
|-- models/
|-- routes/
|-- screens/
|   |-- auth/
|   |-- doctor/
|   |-- notifications/
|   |-- onboarding/
|   |-- patient/
|   |-- profile/
|   |-- role_selection/
|   |-- settings/
|   |-- splash/
|-- services/
|-- theme/
|-- utils/
|-- widgets/
    |-- animations/
    |-- reusable/
```

---

## Main Mobile Modules

### Authentication Module

Handles:

- Login.
- Register.
- Google sign-in.
- Password reset.
- Firebase authentication.
- Backend authentication.
- Role-based routing.

### Splash Module

Handles:

- App startup.
- Network check.
- Server availability check.
- Token validation.
- User role detection.
- Navigation to the correct portal.

### Patient Module

Handles:

- Patient dashboard.
- Vitals.
- Assigned doctor.
- Chat access.
- Notifications.
- AI assessment access.
- Profile and settings.

### Doctor Module

Handles:

- Doctor dashboard.
- Assigned patients.
- Patient search.
- Patient assignment.
- Patient detail view.
- Critical alerts.
- Doctor chat.

### AI Assessment Module

Handles:

- Assessment start screen.
- Dynamic medical questions.
- Answer collection.
- Review screen.
- Report generation screen.
- Report result screen.
- Report history.

### Chat Module

Handles:

- Conversation list.
- Message screen.
- Real-time communication.
- Presence updates.
- Message status updates.

### Notification Module

Handles:

- Notification list.
- Unread status.
- Mark as read.
- Delete notifications.
- Critical alerts.

### Profile and Settings Module

Handles:

- Profile viewing.
- Profile editing.
- Language settings.
- Notification preferences.

---

## Backend Integration

The Flutter app communicates with backend APIs using a centralized API client.

### API Responsibilities

- User authentication.
- Fetching current user.
- Patient assignment.
- Doctor patient list.
- Patient assigned doctor.
- Vitals upload.
- Vitals history.
- Vitals summaries.
- Appointments.
- Notifications.
- AI assessment submission.
- Report history.
- Chat history.

### Main Service Classes

```text
BackendAuthService
DioClient
DoctorApiService
PatientApiService
IoTApiService
AppointmentApiService
NotificationApiService
AiAssessmentApiService
ChatService
PresenceService
UserApiService
TokenService
StorageService
HealthMonitorService
PushNotificationService
```

---

## Wearable Device Integration

The mobile app is prepared to receive readings from a wearable device.

### Wearable Communication

The app listens for data packets from the wearable device using UDP. The monitoring service receives packets, parses them, validates the data, and updates the UI.

### Reading Data

The wearable readings may include:

- Heart rate.
- Oxygen-related value.
- Battery level.
- Connection state.
- Timestamp.

### Important Note

The mobile app can display and upload the oxygen-related field. However, final clinical SpO2 validation depends on the wearable firmware and the correct red/IR sensor algorithm.

---

## Authentication and Authorization

NABDA uses a hybrid authentication approach.

### Firebase Authentication

Used for:

- Email/password authentication.
- Google sign-in.
- Identity management.

### Backend JWT Authentication

Used for:

- Protected backend APIs.
- Patient and doctor workflows.
- Secure API communication.

### Token Storage

Tokens and user data may be stored using:

- Flutter Secure Storage.
- Hive.
- SharedPreferences.

---

## Localization

The mobile app includes localization support for:

- English.
- Arabic.

Localization improves usability for patients and doctors in Egypt and Arabic-speaking environments.

---

## Getting Started

### Prerequisites

Make sure the following are installed:

- Flutter SDK.
- Dart SDK.
- Android Studio or Visual Studio Code.
- Android emulator or physical Android device.
- Firebase project configuration.
- Running backend server.
- Git.

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Gp-team26/gp_app
cd gp_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Add Firebase Configuration

Make sure the following files exist:

```text
lib/firebase_options.dart
android/app/google-services.json
```

### 4. Configure Backend URL

Update the backend base URL in the app configuration file.

The location may be similar to:

```text
lib/core/config/
```

or:

```text
lib/core/api/
```

depending on the final project structure.

### 5. Run the App

```bash
flutter run
```

---

## Environment Configuration

Before running the app, check:

- Firebase configuration is correct.
- Backend server is running.
- Mobile device and backend server can communicate over the same network if using local backend.
- Android permissions are enabled.
- Notification permissions are granted.
- Battery optimization may need to be disabled for background monitoring tests.
- Wearable device and mobile app are connected to the same network if UDP streaming is used.

---

## Android Permissions

The app may require the following Android permissions:

- Internet access.
- Notification permission.
- Foreground service permission.
- Health foreground service type.
- Wake lock.
- Vibration.
- Battery optimization handling.
- Local network access for wearable communication.

These permissions are configured inside the Android project files.

---

## Testing

Suggested testing areas:

### Authentication Testing

- Register as patient.
- Register as doctor.
- Login with valid credentials.
- Login with invalid credentials.
- Google sign-in.
- Password reset.

### Patient Flow Testing

- Open patient dashboard.
- View latest vitals.
- Start monitoring.
- View charts.
- Open notifications.
- Open profile.
- Edit profile.
- Complete AI assessment.
- View report history.
- Chat with assigned doctor.

### Doctor Flow Testing

- Open doctor dashboard.
- View assigned patients.
- Search patients.
- Assign a patient.
- Open patient details.
- View critical states.
- Open doctor notifications.
- Chat with patient.

### Monitoring Testing

- Start foreground service.
- Receive wearable packet.
- Update UI readings.
- Upload reading to backend.
- Trigger warning or critical alert.
- Handle device disconnection.

### Chat Testing

- Send message from patient.
- Receive message on doctor side.
- Send message from doctor.
- Verify conversation history.
- Verify real-time updates.

### AI Assessment Testing

- Start assessment.
- Answer dynamic questions.
- Review answers.
- Submit assessment.
- Display report result.
- Open report history.

---

## Current Limitations

- The mobile app currently uses a service-based architecture with `StatefulWidget` and `setState` in several screens.
- A dedicated state management solution such as BLoC, Riverpod, or Provider may improve scalability.
- Some screens are large and can be refactored into smaller reusable components.
- Some services use static or singleton-like patterns.
- More automated tests should be added.
- Offline support can be improved.
- Final clinical validation of SpO2 depends on firmware and sensor algorithm readiness.
- AI reports are advisory and require doctor review.
- Production deployment requires stronger environment configuration and security hardening.

---

## Future Work

Planned improvements include:

- Add scalable state management.
- Add automated widget tests.
- Add integration tests.
- Improve offline caching.
- Improve accessibility.
- Add medication reminders.
- Add more advanced appointment workflows.
- Improve notification preferences.
- Improve doctor analytics.
- Improve wearable firmware integration.
- Add production environment flavors.
- Add stronger logging and monitoring.
- Extend the system to support more specialties beyond cardiovascular care.

---

## Medical Safety Disclaimer

NABDA is designed to support healthcare follow-up and doctor decision-making. It does not replace professional medical consultation, diagnosis, or treatment.

Any alerts, reports, or AI-generated outputs must be reviewed by qualified healthcare professionals.

---

## Team

Graduation Project Team 2025/2026  
Faculty of Engineering  
Communication and Electronics Department  
Alexandria University

### Team Members

- Mohammad Abdul-Shafi Seddiq
- Ziad Mohammad Elsayed
- Shahd Tamer Khamis
- Malak Essam Kamal
- Ziad Mostafa Zaki
- Yehia Said Gewily

---

## Supervisor

Dr. Aida El-Shafie

---

## License

This project is developed as part of a graduation project at Alexandria University.

If the project is published as open source, add the selected license file and update this section accordingly.
