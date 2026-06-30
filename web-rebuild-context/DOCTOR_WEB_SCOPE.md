# DOCTOR_WEB_SCOPE.md — Feature Scope for Doctor-Only Web App

> **Constraint:** The web app serves **doctors only**. All patient-facing screens, onboarding, IoT device pairing, and patient-side actions are excluded.

---

## 1. MUST INCLUDE — Doctor Web App Features

These features exist in the Flutter app's doctor flow and must be implemented as web pages/views.

---

### 1.1 Doctor Login / Auth

| Property | Value |
|----------|-------|
| **Flutter source** | [`auth_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/auth/auth_screen.dart) (Sign In tab) |
| **What it does** | Email + password login form → `POST /auth/login` → `GET /user/me` → route to dashboard if `role === "DOCTOR"` |
| **APIs used** | `POST /auth/login`, `GET /user/me` |
| **Models** | `LoginRequest`, `AuthResponse`, `User` |
| **Web notes** | Skip Firebase Auth entirely. If user is a `PATIENT`, show error "This portal is for doctors only." |

---

### 1.2 Doctor Registration

| Property | Value |
|----------|-------|
| **Flutter source** | [`auth_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/auth/auth_screen.dart) (Sign Up tab), [`role_selection_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/role_selection/role_selection_screen.dart) |
| **What it does** | Registration form → `POST /auth/register` (with `role: "DOCTOR"`) → auto-login |
| **APIs used** | `POST /auth/register`, `POST /auth/login`, `GET /user/me` |
| **Models** | `RegisterRequest`, `AuthResponse`, `User` |
| **Web notes** | Hard-code `role: "DOCTOR"` in the register payload. Hide role selection — this is a doctor-only portal. Omit `height`/`weight` fields (patient-only). |

---

### 1.3 Doctor Dashboard (Overview Tab)

| Property | Value |
|----------|-------|
| **Flutter source** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — `_buildDashboardContent()` (L643) |
| **What it does** | Overview page with stat cards, critical alerts, recent patients |
| **Content sections** | |

**Header:**
- Doctor name with `"Dr."` prefix
- Doctor avatar (from `profileImageUrl`)
- Current date
- Notification bell icon with unread badge
- Calendar/Appointments shortcut icon

**Stat Cards (2×2 grid + 1 full-width):**
1. **Total Patients** — `_patients.length` → links to patients view
2. **Need Attention** — count of patients with non-Normal priority → warning indicator
3. **Pending Messages** — count of chat contacts with `unreadCount > 0` → links to chats
4. **Today's Appointments** — count of `SCHEDULED` appointments for today → links to appointments with `todayOnly` filter
5. **Missed Appointments** — full-width card, count of `SCHEDULED` appointments in the past → links to appointments missed tab

**Critical Alert Banner:**
- Shows only when `criticalCount > 0` patients
- Red alert card: "X patients need immediate attention"
- Links to patients list

**Recent Patients (top 3):**
- Patient cards showing: name, email, status badge (priority-derived), live heart rate, message button, delete button
- Each card navigates to patient detail

**APIs:**
| API | Purpose |
|-----|---------|
| `GET /doctor/patients/{doctorId}` | Patient list (count + cards) |
| `GET /appointments/doctor/{doctorId}` | Appointment counts |
| `GET /chat/conversations/{doctorId}` | Unread messages count |
| `GET /notifications/{userId}/unread-count` | Notification badge |
| WebSocket `/topic/vitals/{doctorId}` | Live heart rate on patient cards |

---

### 1.4 Chats Tab

| Property | Value |
|----------|-------|
| **Flutter source** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — `_buildChatsContent()` (L1185) |
| **What it does** | List of all chat conversations with patients, sorted by most recent |

**Content:**
- Chat contact list with: patient avatar, name, last message preview, last message time, online/offline status indicator, unread count badge
- Each chat tile opens the chat screen for that patient
- Pull-to-refresh

**APIs:**
| API | Purpose |
|-----|---------|
| `GET /chat/conversations/{userId}` | Conversation list |
| `GET /presence/{partnerId}` | Online/offline for each contact |

---

### 1.5 Patient Chat Screen (Doctor → Patient)

| Property | Value |
|----------|-------|
| **Flutter source** | [`patient_chat_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_chat_screen.dart) |
| **What it does** | 1-to-1 real-time chat between doctor and patient |

**Content:**
- Message history (REST-loaded)
- Real-time messages via STOMP WebSocket
- Send message input + button
- Patient name + online/offline indicator in header
- Patient avatar
- Message bubbles with timestamps
- Read/delivered receipts (ticks)

**APIs:**
| API | Purpose |
|-----|---------|
| `GET /chat/history/{doctorId}/{patientId}` | Load message history |
| WebSocket `/app/chat.send` | Send messages |
| WebSocket `/user/queue/messages` | Receive messages |
| WebSocket `/user/queue/chat-status` | Read/delivered updates |
| `PUT /chat/read/{patientId}/{doctorId}` | Mark as read on open |
| `PUT /chat/deliver/{patientId}/{doctorId}` | Mark as delivered |
| `GET /presence/{patientId}` | Poll presence every 15s |
| `DELETE /notifications/{userId}/chat/{senderId}` | Clear chat notifications on open |

---

### 1.6 My Patients Tab

| Property | Value |
|----------|-------|
| **Flutter source** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — `_buildPatientsContent()` (L1429) |
| **What it does** | Full list of assigned patients with search, assign, and remove |

**Content:**
- Search bar (local filter by name)
- Patient cards: name, email, status badge, live heart rate, message button, delete button
- FAB: "Assign Patient" → opens assign patient sheet
- Swipe/action to remove patient
- Tapping card → Patient Detail page

**Actions:**
| Action | API |
|--------|-----|
| List patients | `GET /doctor/patients/{doctorId}` |
| Search by name | `GET /doctor/search/name?doctorId=X&name=Y` |
| Search by phone | `GET /doctor/search/phone?doctorId=X&phone=Y` |
| Assign patient | `POST /doctor/assign?doctorId=X&patientId=Y` |
| Remove patient | `DELETE /doctor/remove?doctorId=X&patientId=Y` |
| Navigate to chat | route to `/patients/{id}/chat` |
| Navigate to detail | route to `/patients/{id}` |

---

### 1.7 Patient Detail Screen

| Property | Value |
|----------|-------|
| **Flutter source** | [`patient_detail_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_detail_screen.dart) |
| **What it does** | Full patient profile: info card, health status, vitals, AI reports, bio, actions |

**Content sections:**
1. **Patient Info Card** — avatar, name, email, last update time
2. **Health Status Card** — server-computed `healthStatus` with color indicator (CRITICAL/WARNING/NORMAL/UNKNOWN)
3. **Vitals Grid (2×2):**
   - Heart Rate (bpm) — live via WebSocket
   - Blood Oxygen (%) — live via WebSocket
   - Battery Level (%)
   - Next Follow Up (N/A placeholder)
4. **"View Charts" button** — navigates to patient vitals charting screen
5. **"View AI Assessment Reports" button** — navigates to AI report history for this patient
6. **Patient Bio Section** — gender, age, height, weight
7. **FABs:**
   - "Schedule Appointment" → date/time picker → reason dialog → `POST /appointments/schedule`
   - "Send Message" → navigates to patient chat

**Actions from detail:**
- Remove patient from header icon → `DELETE /doctor/remove`
- View vitals charts → `/patients/{id}/vitals`
- View AI reports → `/patients/{id}/reports`
- Schedule appointment → `POST /appointments/schedule`
- Send message → `/patients/{id}/chat`

**APIs:**
| API | Purpose |
|-----|---------|
| `GET /iot/latest/{patientId}` | Current vitals |
| WebSocket `/topic/vitals/{doctorId}` | Live vitals updates |
| `POST /appointments/schedule` | Create appointment |
| `DELETE /doctor/remove?doctorId=X&patientId=Y` | Remove patient |

---

### 1.8 Patient Vitals Charts

| Property | Value |
|----------|-------|
| **Flutter source** | [`patient_vitals_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_vitals_screen.dart) |
| **What it does** | Interactive charts for heart rate + SpO2 with time range toggles |

**Content:**
- Latest vital values header (live via WebSocket)
- Time range selector: 24H / 7D / 30D
- Chart mode selector: HR only / SpO2 only / Both
- Syncfusion-style interactive line charts with tooltips
- WebSocket connection status indicator
- Fit-to-screen toggle

**APIs:**
| API | Purpose |
|-----|---------|
| `GET /iot/latest/{patientId}` | Current reading header |
| `GET /iot/summary/hourly/{patientId}?hours=24` | 24H chart data |
| `GET /iot/summary/{patientId}?days=7` | 7D chart data |
| `GET /iot/summary/{patientId}?days=30` | 30D chart data |
| WebSocket `/topic/vitals/{doctorId}` | Live updates |

---

### 1.9 Patient AI Assessment Reports (Doctor View)

| Property | Value |
|----------|-------|
| **Flutter source** | [`report_history_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/report_history_screen.dart) |
| **What it does** | View a patient's past AI cardiac assessment reports |

**Content:**
- List of past AI reports with dates
- Tapping a report shows full markdown AI analysis
- Uses `isDoctorView: true` flag

**APIs:**
| API | Purpose |
|-----|---------|
| `GET /ai/history/{patientId}` | Fetch patient's AI reports |

---

### 1.10 Doctor Appointments

| Property | Value |
|----------|-------|
| **Flutter source** | [`doctor_appointments_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_appointments_screen.dart) |
| **What it does** | View and manage all appointments with status transitions |

**Content:**
- Tabbed view with filters (Today, Missed, Upcoming, etc.)
- Appointment cards: patient name, date/time, reason, status badge
- Status action buttons: Confirm, Cancel, Complete
- Optimistic update with rollback on failure

**APIs:**
| API | Purpose |
|-----|---------|
| `GET /appointments/doctor/{doctorId}` | List all appointments |
| `PATCH /appointments/{appointmentId}/status` | Update status |
| `PUT /notifications/{userId}/read-appointments` | Auto-mark read |

**Appointment status transitions:**
| Current Status | Available Actions |
|---------------|-------------------|
| `SCHEDULED` | Confirm, Cancel, Complete |
| `CONFIRMED` | Cancel, Complete |
| `CANCELLED` | (no actions) |
| `COMPLETED` | (no actions) |

---

### 1.11 Doctor Profile & Account

| Property | Value |
|----------|-------|
| **Flutter source** | [`profile_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/profile/profile_screen.dart) |
| **What it does** | View and edit doctor's own profile, upload photo, change password, logout |

**Content:**
- Profile photo with upload/remove
- Display fields: Full Name, Email, Phone Number, Date of Birth, Gender
- Edit button → edit mode with inline fields
- Change Password action
- Settings link (notifications toggle, language)
- Logout button with confirmation dialog

**APIs:**
| API | Purpose |
|-----|---------|
| `GET /user/me` | Load current profile |
| `PUT /user/me` | Update profile fields |

---

### 1.12 Notifications

| Property | Value |
|----------|-------|
| **Flutter source** | [`notifications_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/notifications/notifications_screen.dart) |
| **What it does** | Paginated notification list with mark-read and delete actions |

**Content:**
- Notification items: type icon, title, body, time, read/unread indicator
- Infinite scroll pagination (20 per page)
- Mark individual as read
- Mark all as read
- Delete individual
- Delete all
- Tap navigation (CHAT → chat screen, APPOINTMENT → appointments)

**APIs:**
| API | Purpose |
|-----|---------|
| `GET /notifications/{userId}?page=0&size=20` | List (paginated) |
| `GET /notifications/{userId}/unread-count` | Badge count |
| `PUT /notifications/{notificationId}/read/{userId}` | Mark one read |
| `PUT /notifications/{userId}/read-all` | Mark all read |
| `DELETE /notifications/{notificationId}/user/{userId}` | Delete one |
| `DELETE /notifications/{userId}/all` | Delete all |

---

### 1.13 Settings

| Property | Value |
|----------|-------|
| **Flutter source** | [`settings_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/settings/settings_screen.dart) |
| **What it does** | Toggle notifications, change language |

**Content:**
- Notifications toggle (on/off)
- Language selector (English / Arabic)

**Storage:** `localStorage` on web.

---

## 2. INCLUDE ONLY IF NEEDED — Shared Dependencies

These are not standalone pages but are required to support doctor features.

### 2.1 Shared Models

| Model | Why Needed |
|-------|-----------|
| `User` | Doctor's own profile |
| `AuthResponse` | Login response |
| `LoginRequest` | Login payload |
| `RegisterRequest` | Registration payload |
| `PatientResponse` | Patient list cards (doctor sees patient data) |
| `PatientSearchResult` | Search results when assigning patients |
| `HealthMetric` | Patient vitals display |
| `DailySummary` | Vitals charts (7D/30D) |
| `HourlySummary` | Vitals charts (24H) |
| `Appointment` | Appointments list and management |
| `ChatMessage` | Chat messages |
| `ChatContact` | Chat conversations list |
| `NotificationItem` | Notifications list |
| `PresenceStatus` | Online/offline indicator |
| `AiConsultResponse` | Patient AI report view |

### 2.2 Shared APIs (Used by Doctor Workflows)

| Endpoint | Doctor Usage |
|----------|-------------|
| `POST /auth/login` | Doctor login |
| `POST /auth/register` | Doctor registration |
| `GET /user/me` | Doctor profile fetch |
| `PUT /user/me` | Doctor profile update |
| `PUT /user/fcm-token` | Web push registration (if implementing) |
| `GET /iot/latest/{patientId}` | Patient vitals on detail screen |
| `GET /iot/summary/{patientId}` | Patient vitals charts |
| `GET /iot/summary/hourly/{patientId}` | Patient vitals 24H charts |
| `GET /chat/history/{u1}/{u2}` | Chat history with patient |
| `GET /chat/conversations/{userId}` | Conversations list |
| `PUT /chat/read/{s}/{r}` | Mark messages read |
| `PUT /chat/deliver/{s}/{r}` | Mark messages delivered |
| `GET /presence/{userId}` | Online status check |
| `PUT /presence/heartbeat/{userId}` | Keep doctor online |

### 2.3 Shared Components

| Component | Usage |
|-----------|-------|
| Auth guard / route protection | Redirect to login if no JWT |
| Role guard | Block patients from accessing doctor portal |
| HTTP client with auth interceptor | All API calls |
| WebSocket/STOMP client | Chat + live vitals |
| Presence heartbeat manager | Online status |
| Toast/notification display | Success/error feedback |
| Avatar component | User/patient avatars with Base64 image support |

### 2.4 Patient Data Shown Inside Doctor Workflows

| Data | Where Shown |
|------|-------------|
| Patient name, email | Patient list, chat, appointments, detail |
| Patient avatar (profileImageUrl) | Patient list, chat, detail |
| Patient health status (CRITICAL/WARNING/NORMAL/UNKNOWN) | Patient cards, detail status card |
| Patient priority (CRITICAL/HIGH/MEDIUM/LOW) | Patient cards, stat counts |
| Patient vitals (HR, SpO2, battery) | Detail screen, vitals chart, live WebSocket |
| Patient bio (gender, age, height, weight) | Detail screen bio section |
| Patient AI reports | Detail screen → report history |
| Patient chat messages | Chat screen |
| Patient presence (online/offline) | Chat screen, chat list |

---

## 3. DO NOT IMPLEMENT — Patient-Only Features

These exist in the Flutter app but are **NOT** part of the doctor web app.

| Feature | Flutter Screen | Reason |
|---------|---------------|--------|
| Patient Dashboard | [`patient_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/patient_dashboard_screen.dart) | Patient-only screen |
| Patient Onboarding | [`onboarding_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/onboarding/onboarding_screen.dart) | Patient-only flow |
| Patient Role Selection | [`role_selection_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/role_selection/role_selection_screen.dart) | Patient-only (web forces doctor role) |
| AI Assessment Questionnaire | [`assessment_flow_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/assessment_flow_screen.dart) | Patient submits assessments, not doctors |
| AI Assessment Welcome | [`assessment_welcome_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/assessment_welcome_screen.dart) | Patient-only entry point |
| AI Assessment Review | [`review_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/review_screen.dart) | Patient reviews their own submission |
| Patient Report History (self-view) | `GET /ai/my-reports` | Patient views own reports (doctor uses `/ai/history/{patientId}`) |
| Patient-to-Doctor Chat | [`doctor_chat_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/doctor_chat_screen.dart) | Patient's chat screen (mirror of doctor's) |
| Chatbot | [`chatbot_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/chatbot_screen.dart) | Patient-only AI chatbot |
| Patient Follow-Ups | [`follow_ups_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/follow_ups_screen.dart) | Patient-only action items |
| Medical History | [`medical_history_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/medical_history_screen.dart) | Patient views own history |
| Vitals History (patient self-view) | [`vitals_history_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/vitals_history_screen.dart) | Patient views own vitals (doctor uses patient_vitals_screen) |
| IoT Device Connection (UDP) | [`udp_device_service.dart`](file:///e:/side%20projects/gp_app/lib/services/udp_device_service.dart) | Mobile hardware, not applicable to web |
| Background Health Monitor | [`health_monitor_service.dart`](file:///e:/side%20projects/gp_app/lib/services/health_monitor_service.dart) | Android foreground service (isolate) |
| IoT Metric Upload | `POST /iot/upload/{patientId}` | Device sends data, not doctor |
| Patient's Next Appointment | `GET /appointments/patient/{patientId}/next` | Patient dashboard feature |
| Get Assigned Doctor | `GET /patient/doctor/{patientId}` | Patient checks who their doctor is |
| Splash Screen (mobile) | [`splash_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/splash/splash_screen.dart) | Mobile animation + network gate |
| Firestore Service | [`firestore_service.dart`](file:///e:/side%20projects/gp_app/lib/services/firestore_service.dart) | Firebase-specific, not needed on web |
| Hive Local Storage | [`storage_service.dart`](file:///e:/side%20projects/gp_app/lib/services/storage_service.dart) | Mobile local DB, replace with web storage |
| Profile Completion Guard | Splash screen L252 | Patient-only profile check |

---

## 4. APIs NOT Needed for Doctor Web

| Endpoint | Reason |
|----------|--------|
| `POST /iot/upload/{patientId}` | IoT device uploads, not doctor |
| `GET /patient/doctor/{patientId}` | Patient checking their doctor |
| `GET /appointments/patient/{patientId}/next` | Patient dashboard |
| `POST /ai/consult/{patientId}` | Patient submitting assessment |
| `GET /ai/my-reports` | Patient viewing own reports |
| `PUT /user/fcm-token` | Optional — only if implementing web push |
