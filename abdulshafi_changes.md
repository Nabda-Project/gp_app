# Abdulshafi Changes & Commit Plan
**Date:** May 10, 2026

## Overview
This document outlines all the uncommitted changes in the project, categorized into logical groups. These groups represent the major features and fixes implemented recently, including the AI Cardiac Assessment Chatbot, IoT Health Monitoring System (Background Services), and Core UI/Auth enhancements. 

The changes will be committed sequentially according to these groups to maintain a clean and descriptive Git history.

---

## Group 1: Core Configuration & Dependencies Update
**Description:** 
Updates to project dependencies, platform configurations, and utility scripts added to support new features like Foreground Services, UI components, and API tools.

**Files:**
- `pubspec.yaml`
- `pubspec.lock`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `build-release-apk.bat` (New)
- `devtools_options.yaml` (New)

---

## Group 2: Core Authentication, Routing & Profile Fixes
**Description:**
Fixes to authentication screens (password visibility), profile data scoping (fixing image leakage across accounts), and splash screen enhancements to include a strict network and server reachability guard before entering the app. Also includes API endpoint updates.

**Files:**
- `lib/core/api/api_endpoints.dart`
- `lib/core/config/api_config.dart`
- `lib/screens/auth/auth_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/screens/splash/splash_screen.dart`
- `lib/routes/app_routes.dart`
- `lib/main.dart`

---

## Group 3: IoT Health Monitoring & Background Services
**Description:**
Massive integration for the 24-hour Nabda Health Monitoring System. This includes the Android Foreground Service configuration to run the app in the background, UDP listener for local ESP8266 devices, real-time data ingestion, high-frequency synchronization with the backend, new data models, and UI enhancements (Zoomable charts in Patient Vitals, updated Doctor Dashboards).

**Files:**
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/gp_app/MainActivity.kt`
- `lib/services/health_monitor_service.dart` (New)
- `lib/services/udp_device_service.dart` (New)
- `lib/services/iot_api_service.dart`
- `lib/models/device_reading.dart` (New)
- `lib/models/daily_summary_model.dart` (New)
- `lib/models/hourly_summary_model.dart` (New)
- `lib/models/health_metric_model.dart`
- `lib/models/patient_response_model.dart`
- `lib/screens/patient/vitals_history_screen.dart`
- `lib/screens/doctor/patient_vitals_screen.dart` (New)
- `lib/screens/doctor/patient_detail_screen.dart`
- `lib/screens/doctor/doctor_dashboard_screen.dart`
- `lib/widgets/reusable/status_card.dart`

---

## Group 4: AI Cardiac Assessment Chatbot Feature
**Description:**
Complete implementation of the new AI-led Cardiac Assessment Chatbot. This replaces the old chat approach with a structured multi-stage assessment flow, handles UI styling (RTL, dynamic inputs), handles server connectivity states, and merges patient demographic data from the local profile to the backend for AI report generation. Includes documentation for AI prompts.

**Files:**
- `docs/` (New)
- `lib/features/` (New)
- `lib/services/chat_service.dart`
- `lib/screens/patient/patient_dashboard_screen.dart`

---

## Execution
The files will be staged and committed exactly as described above. Deleted artifacts like `android/.kotlin/...` and `status.txt` will be removed or ignored.
