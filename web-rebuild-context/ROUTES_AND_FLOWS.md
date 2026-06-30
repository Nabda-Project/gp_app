# ROUTES_AND_FLOWS.md — Doctor Web App Routes & Page Definitions

> Every page defined here maps directly to a Flutter screen used in the doctor flow.
> No features are invented — all sourced from the Flutter codebase.

---

## Final Route Tree

```
/login                          → Login page
/register                       → Doctor registration
/dashboard                      → Dashboard overview (stat cards, recent patients, alerts)
/chats                          → Conversations list
/chats/:patientId               → Chat with specific patient
/patients                       → Full patient list with search + assign
/patients/:patientId            → Patient detail (vitals, status, bio, actions)
/patients/:patientId/vitals     → Patient vitals charts (24H/7D/30D)
/patients/:patientId/reports    → Patient AI assessment reports
/patients/:patientId/chat       → (alias for /chats/:patientId)
/appointments                   → All appointments with status management
/notifications                  → Notification center (paginated)
/profile                        → Doctor profile view/edit
/settings                       → Notification toggle, language
```

---

## Page Definitions

### 1. Login Page

| Property | Value |
|----------|-------|
| **Page name** | Login |
| **Route path** | `/login` |
| **Purpose** | Authenticate doctor with email + password |
| **Source Flutter screen** | [`auth_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/auth/auth_screen.dart) (Sign In mode) |
| **Required APIs** | `POST /auth/login`, `GET /user/me` |
| **Required models** | `LoginRequest`, `AuthResponse`, `User` |
| **Components needed** | Email input, password input, submit button, error alert, loading overlay |
| **Main actions** | Submit login → validate role is `DOCTOR` → redirect to `/dashboard` |
| **Empty state** | N/A — form is always shown |
| **Error state** | Inline error message: "Invalid email or password" (401), "This portal is for doctors only" (if role is PATIENT), network error toast |
| **Loading state** | Button spinner + form disabled |
| **Permissions/auth** | None — public page. Redirect to `/dashboard` if already authenticated. |
| **Web layout** | Centered card on gradient background. Single column. Logo at top. |

---

### 2. Register Page

| Property | Value |
|----------|-------|
| **Page name** | Register |
| **Route path** | `/register` |
| **Purpose** | Create a new doctor account |
| **Source Flutter screen** | [`auth_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/auth/auth_screen.dart) (Sign Up mode), [`role_selection_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/role_selection/role_selection_screen.dart) |
| **Required APIs** | `POST /auth/register`, `POST /auth/login`, `GET /user/me` |
| **Required models** | `RegisterRequest`, `AuthResponse`, `User` |
| **Components needed** | Full name input, email input, password input, phone input, date of birth picker, gender selector, submit button |
| **Main actions** | Submit → register with `role: "DOCTOR"` → auto-login → redirect to `/dashboard` |
| **Empty state** | N/A — form always shown |
| **Error state** | "Email already exists" (409), validation errors (400), network errors |
| **Loading state** | Button spinner + form disabled |
| **Permissions/auth** | None — public page. Link to `/login` for existing accounts. |
| **Web layout** | Centered card on gradient background. Single column. Logo at top. |

---

### 3. Dashboard

| Property | Value |
|----------|-------|
| **Page name** | Dashboard |
| **Route path** | `/dashboard` |
| **Purpose** | Overview hub — stats, critical alerts, recent patients |
| **Source Flutter screen** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — `_buildDashboardContent()` (L643) |
| **Required APIs** | `GET /doctor/patients/{doctorId}`, `GET /appointments/doctor/{doctorId}`, `GET /chat/conversations/{doctorId}`, `GET /notifications/{userId}/unread-count`, WebSocket `/topic/vitals/{doctorId}` |
| **Required models** | `User`, `PatientResponse`, `Appointment`, `ChatContact`, `HealthMetric` |
| **Components needed** | Stat card grid, alert banner, patient card list (top 3), notification bell with badge, doctor avatar, sidebar/top nav |
| **Main actions** | Click stat card → navigate to relevant page, click patient → `/patients/:id`, click message icon on patient → `/chats/:patientId`, click notification bell → `/notifications`, click calendar icon → `/appointments` |
| **Empty state** | "No patients assigned yet" with link to assign patient |
| **Error state** | Error card with retry button. Network down → full-page "Server Down" view with retry. No internet → full-page "No Internet" view. |
| **Loading state** | Skeleton/shimmer loader for the full dashboard |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Sidebar navigation on left (desktop). Top header with doctor info. Main content area with stat grid + recent patients. Responsive: stack cards vertically on mobile. |

**Stat cards mapping:**

| Card | Value Source | Click Target |
|------|-------------|--------------|
| Total Patients | `patients.length` | `/patients` |
| Need Attention | `patients.filter(p => priority not Normal/LOW).length` | `/patients` (filtered) |
| Pending Messages | `chatContacts.filter(c => c.unreadCount > 0).length` | `/chats` |
| Today's Appointments | appointments where `status===SCHEDULED` AND `date===today` | `/appointments?filter=today` |
| Missed Appointments | appointments where `status===SCHEDULED` AND `date < today` | `/appointments?filter=missed` |

---

### 4. Conversations List

| Property | Value |
|----------|-------|
| **Page name** | Chats |
| **Route path** | `/chats` |
| **Purpose** | List all chat conversations with patients |
| **Source Flutter screen** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — `_buildChatsContent()` (L1185) |
| **Required APIs** | `GET /chat/conversations/{userId}`, `GET /presence/{partnerId}` (per contact) |
| **Required models** | `ChatContact`, `PresenceStatus` |
| **Components needed** | Chat contact tile (avatar, name, last message, time, online dot, unread badge), pull-to-refresh |
| **Main actions** | Tap conversation → `/chats/:patientId`, pull-to-refresh |
| **Empty state** | "No conversations yet — Start chatting from the Patients page!" with refresh button |
| **Error state** | Silent fail — shows whatever data is cached, or empty state |
| **Loading state** | Skeleton list (8 items with avatar placeholders) |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | On desktop: master-detail split (conversation list on left, active chat on right). On mobile: full-page list, navigates to chat page. |

---

### 5. Chat with Patient

| Property | Value |
|----------|-------|
| **Page name** | Patient Chat |
| **Route path** | `/chats/:patientId` |
| **Purpose** | Real-time 1-to-1 messaging with a patient |
| **Source Flutter screen** | [`patient_chat_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_chat_screen.dart) |
| **Required APIs** | `GET /chat/history/{doctorId}/{patientId}`, WebSocket `/app/chat.send`, `/user/queue/messages`, `/user/queue/chat-status`, `PUT /chat/read/{patientId}/{doctorId}`, `PUT /chat/deliver/{patientId}/{doctorId}`, `GET /presence/{patientId}`, `DELETE /notifications/{userId}/chat/{patientId}` |
| **Required models** | `ChatMessage`, `PresenceStatus` |
| **Components needed** | Message bubble list (left/right aligned), text input with send button, header with patient name + avatar + online indicator, scroll-to-bottom button, timestamp separators |
| **Main actions** | Type + send message, scroll through history, auto-scroll on new messages |
| **Empty state** | "No messages yet — say hello!" |
| **Error state** | "Failed to load chat history" with retry. WebSocket disconnect indicator. |
| **Loading state** | Show empty chat immediately, load history in background, append when ready |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Full-height chat panel. Header bar with patient info. Scrollable message area. Fixed input bar at bottom. On desktop with master-detail: shown in right panel. |

**Chat behaviors:**
- On open: mark all messages from patient as read, delete chat notifications
- Presence: poll every 15 seconds
- New message from patient: auto-scroll to bottom, update delivered status
- Real-time status updates: show read/delivered ticks on sent messages

---

### 6. Patient List

| Property | Value |
|----------|-------|
| **Page name** | My Patients |
| **Route path** | `/patients` |
| **Purpose** | Full searchable list of assigned patients with management actions |
| **Source Flutter screen** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — `_buildPatientsContent()` (L1429) |
| **Required APIs** | `GET /doctor/patients/{doctorId}`, `GET /doctor/search/name`, `GET /doctor/search/phone`, `POST /doctor/assign`, `DELETE /doctor/remove`, WebSocket `/topic/vitals/{doctorId}` |
| **Required models** | `PatientResponse`, `PatientSearchResult`, `HealthMetric` |
| **Components needed** | Search bar, patient card list, "Assign Patient" button/dialog, remove confirmation dialog, patient card (name, email, status badge, live HR, message shortcut) |
| **Main actions** | Search patients (local filter), assign new patient (opens search modal → API search → assign), remove patient (confirmation → API delete), tap patient → `/patients/:id`, tap message icon → `/chats/:patientId` |
| **Empty state** | "No patients assigned yet — Assign a new patient to start monitoring them." |
| **Error state** | "Failed to load patients" with retry button |
| **Loading state** | Skeleton list (6 items with avatars) |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Full-width content area. Search bar at top. Card list below. "Assign Patient" button (top-right or floating). On desktop: use table layout for better data density. |

**Assign Patient flow:**
1. Click "Assign Patient" → modal opens
2. Choose search type: name or phone
3. Type query → debounced API call (`GET /doctor/search/name` or `/search/phone`)
4. Results show patients NOT yet assigned
5. Click "Add" on result → `POST /doctor/assign`
6. Optimistic add to patient list
7. Silent background refresh to sync

---

### 7. Patient Detail

| Property | Value |
|----------|-------|
| **Page name** | Patient Detail |
| **Route path** | `/patients/:patientId` |
| **Purpose** | Comprehensive view of a single patient — vitals, status, bio, actions |
| **Source Flutter screen** | [`patient_detail_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_detail_screen.dart) |
| **Required APIs** | `GET /iot/latest/{patientId}`, WebSocket `/topic/vitals/{doctorId}`, `POST /appointments/schedule`, `DELETE /doctor/remove`, `GET /ai/history/{patientId}` (via linked page) |
| **Required models** | `PatientResponse`, `HealthMetric`, `Appointment`, `AiConsultResponse` |
| **Components needed** | Patient info card (avatar, name, email), health status badge, vitals grid (HR, SpO2, battery, follow-up), "View Charts" link, "View AI Reports" link, patient bio section (gender, age, height, weight), "Schedule Appointment" action, "Send Message" action, "Remove Patient" action |
| **Main actions** | View live vitals, navigate to charts (`/patients/:id/vitals`), navigate to AI reports (`/patients/:id/reports`), schedule appointment (date/time/reason picker), send message (`/chats/:patientId`), remove patient |
| **Empty state** | Vitals: "No readings yet — --" values. Bio: "N/A" for missing fields. |
| **Error state** | Vitals load error: show "--" with subtle error indicator. Critical failure: error card with retry. |
| **Loading state** | Shimmer for vitals grid, "--" placeholders until data loads |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Single-page layout. On desktop: two-column layout (info+vitals on left, bio+actions on right). On mobile: single column scroll. Breadcrumb: Dashboard > Patients > Patient Name |

**Schedule Appointment flow (from patient detail):**
1. Click "Schedule Appointment"
2. Date picker → Time picker → Reason input (optional)
3. Validation: cannot schedule in the past
4. `POST /appointments/schedule` with `{ doctorId, patientId, appointmentDate, reason }`
5. Success toast

---

### 8. Patient Vitals Charts

| Property | Value |
|----------|-------|
| **Page name** | Patient Vitals |
| **Route path** | `/patients/:patientId/vitals` |
| **Purpose** | Interactive line charts for heart rate and SpO2 |
| **Source Flutter screen** | [`patient_vitals_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_vitals_screen.dart) |
| **Required APIs** | `GET /iot/latest/{patientId}`, `GET /iot/summary/hourly/{patientId}?hours=24`, `GET /iot/summary/{patientId}?days=7`, `GET /iot/summary/{patientId}?days=30`, WebSocket `/topic/vitals/{doctorId}` |
| **Required models** | `HealthMetric`, `HourlySummary`, `DailySummary` |
| **Components needed** | Time range toggles (24H/7D/30D), chart mode toggle (HR/SpO2/Both), interactive line chart with tooltips, current vitals header, WebSocket status indicator |
| **Main actions** | Switch time range, switch metric mode, hover/click chart data points |
| **Empty state** | "No vitals data available for this patient" |
| **Error state** | "Failed to load chart data" with retry |
| **Loading state** | Chart area placeholder/skeleton, "--" vitals header |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Full-width chart area. Controls bar above chart. Current vitals card at top. Breadcrumb: Dashboard > Patients > [Name] > Vitals. Use a web charting library (e.g., Chart.js, Recharts, ApexCharts). |

---

### 9. Patient AI Reports

| Property | Value |
|----------|-------|
| **Page name** | AI Assessment Reports |
| **Route path** | `/patients/:patientId/reports` |
| **Purpose** | View patient's past AI cardiac assessment reports |
| **Source Flutter screen** | [`report_history_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/report_history_screen.dart) (with `isDoctorView: true`) |
| **Required APIs** | `GET /ai/history/{patientId}` |
| **Required models** | `AiConsultResponse` |
| **Components needed** | Report list (date, summary), report detail view with markdown rendering, expand/collapse or modal for full report |
| **Main actions** | Browse report list, click to view full AI report (rendered markdown) |
| **Empty state** | "No AI assessment reports available for this patient" |
| **Error state** | "Failed to load reports" with retry |
| **Loading state** | Centered spinner |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Report list on left, selected report rendered on right (desktop). Single column with expand on mobile. Use a markdown renderer (e.g., `react-markdown`, `marked`). Breadcrumb: Dashboard > Patients > [Name] > AI Reports. |

---

### 10. Appointments

| Property | Value |
|----------|-------|
| **Page name** | Appointments |
| **Route path** | `/appointments` |
| **Purpose** | View and manage all doctor appointments |
| **Source Flutter screen** | [`doctor_appointments_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_appointments_screen.dart) |
| **Required APIs** | `GET /appointments/doctor/{doctorId}`, `PATCH /appointments/{appointmentId}/status` |
| **Required models** | `Appointment` |
| **Components needed** | Tab/filter bar (Today, Missed, Upcoming, All), appointment cards (patient name, date/time, reason, status badge, action buttons), status action buttons |
| **Main actions** | Filter by tab, confirm appointment, cancel appointment, mark as completed |
| **Empty state** | "No appointments found" |
| **Error state** | "Failed to load appointments" with retry |
| **Loading state** | Skeleton list |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Full-width content area. Tab bar at top for filtering. Appointment cards or table rows below. On desktop: consider a table layout with inline action buttons. On mobile: card layout. Breadcrumb: Dashboard > Appointments. |

**Query param filters (optional, client-side):**
- `/appointments?filter=today` — pre-select Today tab
- `/appointments?filter=missed` — pre-select Missed tab

**Filter logic (all client-side, data from single API call):**

| Tab | Filter |
|-----|--------|
| Today | `status === 'SCHEDULED'` AND `appointmentDate` is today (local time) |
| Missed | `status === 'SCHEDULED'` AND `appointmentDate < today` |
| Upcoming | `status === 'SCHEDULED'` AND `appointmentDate >= today` |
| Confirmed | `status === 'CONFIRMED'` |
| Completed | `status === 'COMPLETED'` |
| Cancelled | `status === 'CANCELLED'` |

**Optimistic update pattern:**
1. User clicks "Confirm" → immediately update UI to `CONFIRMED`
2. `PATCH /appointments/{id}/status` with `{ status: "CONFIRMED" }`
3. On error → rollback + refetch + error toast

---

### 11. Notifications

| Property | Value |
|----------|-------|
| **Page name** | Notifications |
| **Route path** | `/notifications` |
| **Purpose** | View, manage, and act on notifications |
| **Source Flutter screen** | [`notifications_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/notifications/notifications_screen.dart) |
| **Required APIs** | `GET /notifications/{userId}?page=0&size=20`, `PUT /notifications/{notificationId}/read/{userId}`, `PUT /notifications/{userId}/read-all`, `DELETE /notifications/{notificationId}/user/{userId}`, `DELETE /notifications/{userId}/all` |
| **Required models** | `NotificationItem` |
| **Components needed** | Notification item (type icon, title, body, relative time, read/unread indicator), infinite scroll, "Mark all read" button, "Delete all" button, individual mark-read and delete actions |
| **Main actions** | Scroll to load more, tap notification (navigate by type), mark read, delete |
| **Empty state** | "No notifications" with bell icon |
| **Error state** | "Failed to load notifications" with retry |
| **Loading state** | Skeleton list, then loading-more spinner at bottom |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Full-width list or dropdown panel. On desktop: could be a sidebar panel or full page. Breadcrumb: Dashboard > Notifications. |

**Tap navigation:**

| Notification Type | Navigate To |
|-------------------|-------------|
| `CHAT` | `/chats/:relatedId` (relatedId = sender's userId) |
| `APPOINTMENT_SCHEDULED` | `/appointments` |
| `APPOINTMENT_CONFIRMED` | `/appointments` |
| `PATIENT_ASSIGNED` | `/patients` |
| Other / unknown | No navigation — just mark as read |

---

### 12. Doctor Profile

| Property | Value |
|----------|-------|
| **Page name** | Profile |
| **Route path** | `/profile` |
| **Purpose** | View and edit doctor's own profile |
| **Source Flutter screen** | [`profile_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/profile/profile_screen.dart) |
| **Required APIs** | `GET /user/me`, `PUT /user/me` |
| **Required models** | `User`, `UpdateProfileRequest` |
| **Components needed** | Avatar with upload/remove, display fields (name, email, phone, DOB, gender), edit mode with form inputs, change password section, logout button with confirmation, link to settings |
| **Main actions** | View profile, edit fields, upload/remove photo, change password, logout |
| **Empty state** | N/A — always shows current user data |
| **Error state** | "Failed to update profile" toast on save error |
| **Loading state** | Shimmer for profile fields on initial load. Save button spinner during update. |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Centered card or two-column layout. Avatar at top center. Form fields below. Save/Cancel buttons. On desktop: sidebar makes this always accessible. |

**Profile image flow:**
1. Click avatar → file picker
2. Select image → preview
3. Convert to Base64 data URI
4. `PUT /user/me` with `{ profileImageUrl: "data:image/jpeg;base64,..." }`
5. To remove: `PUT /user/me` with `{ profileImageUrl: "" }`

---

### 13. Settings

| Property | Value |
|----------|-------|
| **Page name** | Settings |
| **Route path** | `/settings` |
| **Purpose** | Toggle notifications and change language |
| **Source Flutter screen** | [`settings_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/settings/settings_screen.dart) |
| **Required APIs** | None (local preferences only) |
| **Required models** | None (stored in `localStorage`) |
| **Components needed** | Notifications toggle switch, language dropdown (English/Arabic) |
| **Main actions** | Toggle notifications, change language |
| **Empty state** | N/A |
| **Error state** | N/A |
| **Loading state** | N/A |
| **Permissions/auth** | ✅ Requires JWT + role === DOCTOR |
| **Web layout** | Simple settings card. Can be a sub-section of the Profile page or a separate page. |

---

## Navigation Structure

### Desktop Layout (Recommended)

```
┌─────────────────────────────────────────────────────────┐
│  ┌──────────┐  ┌─────────────────────────────────────┐  │
│  │ Sidebar  │  │  Top Header Bar                     │  │
│  │          │  │  Doctor Name | Notif Bell | Avatar   │  │
│  │ Dashboard│  ├─────────────────────────────────────┤  │
│  │ Patients │  │                                     │  │
│  │ Chats    │  │  Main Content Area                  │  │
│  │ Appts    │  │                                     │  │
│  │ Notifs   │  │  (Dashboard / Patients / etc.)      │  │
│  │ ──────── │  │                                     │  │
│  │ Profile  │  │                                     │  │
│  │ Settings │  │                                     │  │
│  │ Logout   │  │                                     │  │
│  └──────────┘  └─────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Mobile Layout

```
┌────────────────────────┐
│  Top App Bar           │
│  Title | Notif | Menu  │
├────────────────────────┤
│                        │
│  Content Area          │
│                        │
├────────────────────────┤
│  Bottom Nav Bar        │
│  Dash|Chats|Pts|Profile│
└────────────────────────┘
```

### Sidebar Items

| Icon | Label | Route | Badge |
|------|-------|-------|-------|
| 📊 | Dashboard | `/dashboard` | – |
| 👥 | Patients | `/patients` | Patient count |
| 💬 | Chats | `/chats` | Total unread messages |
| 📅 | Appointments | `/appointments` | Today's count |
| 🔔 | Notifications | `/notifications` | Unread count |
| ── | ── (separator) | ── | ── |
| 👤 | Profile | `/profile` | – |
| ⚙️ | Settings | `/settings` | – |
| 🚪 | Logout | (action) | – |

---

## Auth Flow Diagram

```
User arrives at web app
  │
  ├─ Has JWT in localStorage?
  │   ├─ NO → Redirect to /login
  │   └─ YES →
  │       ├─ GET /user/me succeeds?
  │       │   ├─ YES, role === DOCTOR → Allow access
  │       │   ├─ YES, role === PATIENT → Show error + redirect to /login
  │       │   └─ NO (401/403) →
  │       │       ├─ Has stored credentials?
  │       │       │   ├─ YES → Auto-refresh (POST /auth/login) → retry
  │       │       │   └─ NO → Redirect to /login
  │       │       └─ Refresh failed → Clear session → /login
  │       └─ (continue to requested page)
  │
  ├─ On /login:
  │   ├─ Submit email + password
  │   ├─ POST /auth/login → get JWT
  │   ├─ GET /user/me → check role
  │   ├─ role === DOCTOR? → Store JWT + credentials → /dashboard
  │   └─ role !== DOCTOR? → Error: "This portal is for doctors only"
  │
  └─ On /register:
      ├─ Submit form (role auto-set to DOCTOR)
      ├─ POST /auth/register → POST /auth/login
      ├─ GET /user/me → confirm DOCTOR role
      └─ Store JWT + credentials → /dashboard
```

---

## WebSocket Lifecycle

```
After login succeeds:
  │
  ├─ Connect STOMP over SockJS to ws://{host}/ws
  │   Headers: { Authorization: "Bearer <JWT>" }
  │
  ├─ Subscribe to:
  │   ├─ /user/queue/messages       → Chat messages
  │   ├─ /user/queue/chat-status    → Read/delivered receipts
  │   ├─ /user/queue/system         → System events (patient assigned, appointment changes)
  │   └─ /topic/vitals/{doctorId}   → Live patient vitals
  │
  ├─ Start presence heartbeat:
  │   └─ PUT /presence/heartbeat/{doctorId} every 30 seconds
  │
  └─ On logout / tab close:
      ├─ STOMP deactivate
      └─ Clear heartbeat interval
```

---

## Real-Time Event Handling

| WebSocket Event | UI Update |
|-----------------|-----------|
| `/user/queue/messages` (new chat msg) | Refresh chat list, show heads-up notification if sender ≠ self |
| `/user/queue/chat-status` (read/delivered) | Update tick marks in active chat |
| `/user/queue/system` type=`PATIENT_ASSIGNED` | Silent refresh patient list + notification count |
| `/user/queue/system` type=`PATIENT_REMOVED` | Silent refresh patient list + notification count |
| `/user/queue/system` type=`APPOINTMENT_*` | Refresh appointment counts, show notification for SCHEDULED |
| `/topic/vitals/{doctorId}` | Update live HR on patient cards + patient detail vitals |
