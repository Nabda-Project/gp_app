# PRODUCT_CONTEXT.md — NABDA Doctor Web App

> This document captures the product purpose, scope, users, and core value
> proposition of NABDA so an AI agent can rebuild the **doctor-only web app**
> with the same product identity and behavior as the existing Flutter app.

All facts in this document are extracted from the Flutter source. Where the
Flutter app does not provide a fact, the field is marked `Unknown` or
`Needs verification`.

---

## 1. Product name

- **Name:** NABDA
- **Source:** `lib/utils/constants.dart` → `AppStrings.appName = "NABDA"`
- **Tagline:** "Your Health, Your Pulse" (splash) / "Your Health, Your Hands" (onboarding, EN locale)
- **Source:** `lib/screens/splash/splash_screen.dart:470`, `lib/l10n/app_localizations_generated_en.dart:18`

NABDA is a connected healthcare follow-up + diagnostic support system focused
on **cardiovascular monitoring** with structured AI-assisted cardiac
assessment, real-time chat, and continuous vitals monitoring via a wearable.

Source: `README.md` (project overview).

---

## 2. Domain & medical scope

- **Primary domain:** cardiology / cardiovascular monitoring & follow-up.
- **Tracked vitals (current):**
  - Heart Rate (BPM) — from analog pulse sensor (`PULSE_reading`).
  - SpO₂ (%) — sourced from MAX30105 reading (see `DeviceReading` docs;
    firmware currently exposes HR-like value via SpO₂ field).
  - Battery level (% — converted from raw ADC0832 value).
- **Source:** `lib/models/device_reading.dart`, `lib/services/health_monitor_service.dart`.

**Disclaimer the web app MUST preserve:** "AI reports are advisory only and
must be reviewed by qualified medical professionals."
Source: `README.md` "Medical Safety Disclaimer".

---

## 3. Roles

The platform has exactly two roles. The new web app is for **doctors only**.

| Role     | Backend enum | Display label | Notes |
|----------|--------------|---------------|-------|
| Doctor   | `DOCTOR`     | `Doctor`      | Web app target |
| Patient  | `PATIENT`    | `Patient`     | NOT in scope of web app |

Source: `lib/models/user_model.dart:71-94`, `lib/services/auth_service.dart:60`.

The Flutter app mixes Title-case (UI) and UPPER-case (backend enum). The web
app must use the same conversions on the wire.

---

## 4. Doctor product overview (web app scope)

From `README.md` "Doctor Portal" and the doctor screens in
`lib/screens/doctor/*`:

### 4.1 Dashboard
- Total assigned patients count.
- Critical / warning case counts.
- Today's appointments count.
- Missed appointments count.
- Pending unread chat count.
- Recent patients list (top 3).
- Critical alert card when any patient priority is HIGH/CRITICAL.
- Real-time live heart rate per patient (via WebSocket vitals stream).

### 4.2 Patient management
- View assigned patients list with priority/health badges.
- Search assigned patients (client-side filter on name).
- Open patient details (vitals snapshot, bio, status).
- Assign a NEW patient via search (by name OR by phone) bottom sheet.
- Remove a patient (swipe in mobile; the web equivalent is a delete action).
- Drill into patient → chat / charts / AI report history / schedule appointment.

### 4.3 Patient detail
- Patient info card (avatar, name, email, last update).
- Health status card (CRITICAL / WARNING / NORMAL / UNKNOWN, color-coded).
- Vitals grid: HR, SpO₂, Battery, Next follow-up placeholder.
- "View Charts" link → vitals history with summaries.
- "View AI reports" button → AI report history (doctor view).
- Bio: gender, age (computed), height (cm), weight (kg).
- Floating actions: Schedule appointment, Send message.

### 4.4 Patient vitals (charts)
- Range selector (1d / 7d / 30d, etc., 1d uses hourly summary).
- Modes: HR-only, SpO₂-only, Both.
- Live updates via STOMP `/topic/vitals/{doctorId}`.
- Min/avg/max statistics summary.

### 4.5 Doctor appointments
- 4 tabs: Upcoming, Missed, Completed, Cancelled.
- Status transitions: SCHEDULED → CONFIRMED / COMPLETED / CANCELLED / MISSED.
- Schedule new appointment from a patient's detail screen (date + time + reason).

### 4.6 Chat (conversations + messages)
- Conversations list (last message preview, unread count badge, online dot).
- 1-1 chat with a patient (real-time STOMP, message read/delivered receipts,
  presence with last-seen).

### 4.7 Notifications
- Paginated notifications list (page size 20).
- Mark single / mark all / mark chat-thread / mark appointments / delete.

### 4.8 Profile
- Edit personal info, change avatar (image upload as base64 data URI),
  language, notification toggle, logout.

### 4.9 AI report history (read-only, doctor view)
- View past AI consult reports for the selected patient.
- Doctor uses `GET /api/ai/history/{patientId}` (NOT `/ai/my-reports`).
- The web app should support listing + viewing detail + (optional) PDF
  export later (mobile uses `pdf` + `printing` packages).

---

## 5. What is OUT of scope for the web app

- Patient role entirely (patient dashboard, patient vitals self-view,
  patient profile from patient perspective, the patient-facing AI assessment flow).
- Wearable UDP listener / background health monitor service (Android-only).
- Foreground service / local critical alert notifications.
- Patient onboarding / role selection (web is doctor-only).
- AI assessment authoring flow (`/assessment_welcome`, `/assessment_flow`,
  `/assessment_review`, `/report_loading`, `/report_result`) — only the
  **doctor-side read-only AI report history** is in scope.

Source: routes in `lib/routes/app_routes.dart`, AI screens in
`lib/features/ai_assessment/screens/*`.

---

## 6. Tech & product invariants the web app must preserve

- **Brand colors (exact):** primary `#407BFF`, secondary `#00B4D8`,
  dark `#03045E`, accent teal `#00BFA5`, error `#E53935`, grey `#94A3B8`,
  light grey `#E2E8F0`, background `#F8FAFC`.
  Source: `lib/utils/constants.dart`.
- **Primary gradient:** linear top-left → bottom-right
  `#407BFF` → `#00B4D8`. Used on splash and the doctor-dashboard sliver
  header.
- **Typography:** `Roboto` (Latin / EN), `Cairo` for Arabic content (used
  in PDF export and some bilingual labels).
- **Languages:** English + Arabic with RTL.
- **Disclaimers:** medical safety disclaimer remains visible on AI reports
  and in the about section.

---

## 7. Backend (single source of truth)

- **Base URL:**
  `http://smart-medical-api-env.eba-jxdmccmi.us-east-1.elasticbeanstalk.com/api`
- **WebSocket URL:**
  `ws://smart-medical-api-env.eba-jxdmccmi.us-east-1.elasticbeanstalk.com/ws`
- **Real-time transport:** STOMP over SockJS.
- **Auth:** Firebase identity + backend JWT (Bearer token).

Source: `lib/core/config/api_config.dart`, `lib/core/api/dio_client.dart`,
`lib/services/chat_service.dart`.

The same endpoints, auth flow, and transport must be reused by the web app.

---

## 8. Stakeholders & Authors

Per `README.md`: graduation project, Alexandria University Faculty of
Engineering, Communication & Electronics Department, supervisor Dr. Aida
El-Shafie. Team members listed in README §"Team Members".

This is needs verification for non-academic use (production, licensing,
HIPAA-like compliance), and should be confirmed with the team before
publishing the web app publicly.

---

## 9. Success criteria for the rebuild

The web app is "done" when:
1. A doctor can log in with the same credentials used in the mobile app.
2. The dashboard, patients list, patient detail, vitals charts, chat,
   appointments, notifications, profile, and AI report history are all
   functional against the same backend.
3. Real-time messages, vitals, and system events arrive through the same
   STOMP destinations.
4. Brand colors, gradient, typography, and component visual language
   match the mobile app.
5. Bilingual EN/AR (with RTL) is supported.

---

## 10. Things deliberately left untouched

- Patient-side flows.
- Background health monitor (Android-only foreground service).
- The wearable firmware / UDP packet format.
