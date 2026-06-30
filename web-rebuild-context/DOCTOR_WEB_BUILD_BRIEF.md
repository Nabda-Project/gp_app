# DOCTOR_WEB_BUILD_BRIEF.md — Consolidated Web Build Brief

> **Target Audience:** AI Coding Agent / Web Developer
> **Goal:** Rebuild the doctor-facing portal of the NABDA mobile application as a responsive web app from scratch.
> **Scope:** Strictly **doctor-only**. No patient-facing pages or actions should be implemented.
> **Visual Direction:** Premium medical SPA using glassmorphism, CSS variables, dark-blue gradients, and interactive charts.

---

## 1. Product Summary
NABDA is a connected-care telemedicine ecosystem. The mobile application allows patients to record real-time vitals using a wearable device (via UDP), chat with their doctors, and request AI-powered cardiac assessments. 
The **Doctor Web Portal** is the administrative and monitoring dashboard for medical professionals to track their assigned patients, respond to patient messages, review live/historical vitals, manage appointments, and inspect AI-generated cardiac reports.

---

## 2. Doctor-Only Scope (Must Build)

| Feature | Sourced From | API Dependencies |
|---------|--------------|------------------|
| **Doctor Auth** | [`auth_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/auth/auth_screen.dart) | `POST /auth/login`, `GET /user/me` |
| **Doctor Register** | [`auth_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/auth/auth_screen.dart) | `POST /auth/register`, `POST /auth/login`, `GET /user/me` |
| **Doctor Dashboard** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) | `GET /doctor/patients/*`, `GET /appointments/doctor/*`, `GET /chat/conversations/*`, WebSocket `/topic/vitals/{doctorId}` |
| **Patient List** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) | `GET /doctor/patients/*`, `POST /doctor/assign`, `DELETE /doctor/remove` |
| **Patient Search** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) | `GET /doctor/search/name`, `GET /doctor/search/phone` |
| **Patient Details** | [`patient_detail_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_detail_screen.dart) | `GET /iot/latest/{patientId}`, WebSocket `/topic/vitals/{doctorId}` |
| **Vitals Charts** | [`patient_vitals_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_vitals_screen.dart) | `GET /iot/summary/*`, `GET /iot/summary/hourly/*`, WebSocket `/topic/vitals/{doctorId}` |
| **AI Assessment Reports** | [`report_history_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/report_history_screen.dart) | `GET /ai/history/{patientId}` |
| **Conversations List** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) | `GET /chat/conversations/{userId}`, `GET /presence/{partnerId}` |
| **Active Messaging** | [`patient_chat_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_chat_screen.dart) | `GET /chat/history/*`, WebSocket STOMP send/receive/receipts, `PUT /chat/read/*`, `PUT /chat/deliver/*` |
| **Appointments** | [`doctor_appointments_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_appointments_screen.dart) | `GET /appointments/doctor/*`, `PATCH /appointments/{id}/status`, `POST /appointments/schedule` |
| **Notification Center** | [`notifications_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/notifications/notifications_screen.dart) | `GET /notifications/*`, `PUT /notifications/*`, `DELETE /notifications/*` |
| **Profile & Settings** | [`profile_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/profile/profile_screen.dart) | `GET /user/me`, `PUT /user/me` |

---

## 3. What Must NOT Be Built (Excluded)

The following patient-only modules must be skipped entirely during the web portal build:
- **Patient Intake / Onboarding**: [`onboarding_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/onboarding/onboarding_screen.dart) (welcome sliders/prompts).
- **Patient Dashboard & Menu**: Vitals monitoring, chatbot access, patient local history tabs.
- **AI Assessment Form Submissions**: [`assessment_flow_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/assessment_flow_screen.dart) (patients answer intake question blocks; doctors only view historical reports).
- **AI Chatbot Interface**: [`chatbot_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/chatbot_screen.dart) (real-time automated medical Q&A).
- **IoT Hardware Integration**: UDP listener scripts (`RawDatagramSocket` binding on port 4210) and mobile-device-specific pairing states.
- **Mobile-Background Monitoring Isolate**: [`health_monitor_service.dart`](file:///e:/side%20projects/gp_app/lib/services/health_monitor_service.dart) (runs background metric processing loops).
- **Firestore DB Calls**: [`firestore_service.dart`](file:///e:/side%20projects/gp_app/lib/services/firestore_service.dart) (Firebase database profile syncs).

---

## 4. Web Route Tree

```
/login                          → Login view (Public)
/register                       → Registration form (Public)
/dashboard                      → Overview stats, alerts, recent patients (Protected)
/patients                       → All assigned patients, assign patient drawer (Protected)
/patients/:patientId            → Detailed view: live vitals, bio info, direct actions (Protected)
/patients/:patientId/vitals     → Metric charts (24H hourly/7D daily/30D daily summaries) (Protected)
/patients/:patientId/reports    → AI reports history list & markdown render viewport (Protected)
/chats                          → Master split layout: conversations menu & active chat pane (Protected)
/chats/:patientId               → Direct chat thread view (alias of `/chats`) (Protected)
/appointments                   → Appointments management grid: schedule filter tabs (Protected)
/notifications                  → Notification feed with paginated loading list (Protected)
/profile                        → Edit name, phone, password, Base64 profile picture (Protected)
/settings                       → Toggle system notifications, language selector (Protected)
```

---

## 5. Main Doctor User Flows

### Flow 1: Search & Assign Patient
```
[Patients View] ──→ Click "Assign Patient" ──→ Open Modal 
  ──→ Enter name/phone query ──→ Debounced API call 
  ──→ Display results ──→ Click "Add" ──→ Call POST /doctor/assign 
  ──→ Optimistic add to patient list ──→ Re-sync list in background
```

### Flow 2: Live Vitals Monitoring
```
[Patient Details / Vitals Graph] ──→ Load current metrics via GET /iot/latest
  ──→ Connect STOMP WebSocket ──→ Subscribe to /topic/vitals/{doctorId}
  ──→ Incoming payloads trigger state changes 
  ──→ Real-time Heart Rate pulses & charts redraw dynamically
```

### Flow 3: Interactive Chatting
```
[Chats View] ──→ Select Patient ──→ Call GET /chat/history & PUT /chat/read
  ──→ Clear chat notifications via DELETE API ──→ Load message scroll timeline
  ──→ Poll patient presence (online status / last-seen tag) every 15 seconds
  ──→ Type & Send ──→ Push to WebSocket /app/chat.send 
  ──→ Incoming message on /user/queue/messages ──→ Update UI + mark delivered
```

### Flow 4: Appointment Management
```
[Appointments View] ──→ Load appointments via GET /appointments/doctor/{id}
  ──→ Filter tabs: Missed / Today / Upcoming
  ──→ Doctor clicks "Confirm" or "Complete" on card ──→ Optimistically update card badge
  ──→ PATCH /appointments/{id}/status ──→ If API fails, rollback state and toast error
```

---

## 6. Auth / Session Behavior

```
               ┌──────────────────────────────┐
               │     User visits Doctor App   │
               └──────────────┬───────────────┘
                              │
               Has JWT in LocalStorage / Cookie?
                ├── No  ──→ Redirect to /login
                └── Yes ──→ Call GET /user/me
                             ├── Success & role === "DOCTOR" ─→ Access Granted
                             ├── Success & role === "PATIENT"─→ Show unauthorized error
                             └── Failure (401 / 403)
                                  ├── Re-auth via email/pass credentials ─→ Success (new JWT)
                                  └── Re-auth fails ─→ Wipe JWT, disconnect WS, route to /login
```

*Note: For the web rebuild, Firebase authentication should be skipped. Use the backend JWT as the single source of truth for sessions.*

---

## 7. API Summary

Base URL: `http://smart-medical-api-env.eba-jxdmccmi.us-east-1.elasticbeanstalk.com/api`  
WebSocket Endpoint: `ws://smart-medical-api-env.eba-jxdmccmi.us-east-1.elasticbeanstalk.com/ws`

### Key Endpoints

| Endpoint | Method | Role Guard | Description |
|----------|--------|------------|-------------|
| `/auth/login` | `POST` | Public | Returns AuthResponse (token) |
| `/auth/register` | `POST` | Public | Register doctor account (hardcode `role: "DOCTOR"`) |
| `/user/me` | `GET` | Doctor | Fetch profile details (id, role, profileImageUrl, etc.) |
| `/user/me` | `PUT` | Doctor | Update profile (passwords, base64 images, phone, name) |
| `/doctor/assign` | `POST` | Doctor | Query params: `doctorId`, `patientId`. Empty body return. |
| `/doctor/patients/{id}`| `GET` | Doctor | Fetch all patients assigned to a doctor |
| `/doctor/search/name` | `GET` | Doctor | Search unassigned patients. Query: `doctorId`, `name` |
| `/doctor/search/phone` | `GET` | Doctor | Search unassigned patients. Query: `doctorId`, `phone` |
| `/doctor/remove` | `DELETE` | Doctor | Unassign patient. Query: `doctorId`, `patientId` |
| `/iot/latest/{patientId}`| `GET` | Shared | Latest sensor metrics for a patient (404-safe) |
| `/iot/summary/{id}` | `GET` | Shared | Get daily patient summary (default 7 days) |
| `/iot/summary/hourly/{id}`| `GET`| Shared | Get hourly patient summary (default 24 hours) |
| `/chat/history/{u1}/{u2}`| `GET`| Shared | Fetch message thread history |
| `/chat/conversations/{id}`| `GET`| Shared | Get list of active conversation partners with unread counts |
| `/chat/read/{sender}/{rec}`| `PUT`| Shared | Mark messages as read |
| `/chat/deliver/{sender}/{rec}`| `PUT`| Shared | Mark messages as delivered |
| `/presence/{userId}` | `GET` | Shared | Check target online status and lastSeen |
| `/presence/heartbeat/{id}`| `PUT`| Shared | Heartbeat ping. Run every 30 seconds. |
| `/appointments/schedule`| `POST` | Doctor | Schedule appointment. Payload contains UTC ISO date. |
| `/appointments/doctor/{id}`| `GET`| Doctor | List all appointments |
| `/appointments/{id}/status`| `PATCH`| Doctor | Update status payload: `{ status: "CONFIRMED" }` |
| `/notifications/{userId}`| `GET` | Shared | Paginated notifications feed. Query: `page`, `size` |
| `/notifications/{userId}/unread-count`| `GET`| Shared| Unread notification badge count |
| `/ai/history/{patientId}`| `GET` | Doctor | Fetch assessment reports history for doctor view |

### WebSocket Subscriptions & STOMP Destinations

| WebSocket Path | Protocol | Purpose |
|----------------|----------|---------|
| `/app/chat.send` | STOMP Send | Send messages |
| `/user/queue/messages` | STOMP Sub | Real-time chat messages |
| `/user/queue/chat-status`| STOMP Sub | Message read/delivered receipts |
| `/user/queue/system` | STOMP Sub | Real-time alerts (appointments, patient assignments) |
| `/topic/vitals/{doctorId}`| WebSocket Sub | Live heart rate broadcast of doctor's assigned patients |

---

## 8. Data Model Summary (TypeScript Schema)

Map backend entities to strict TypeScript interfaces:

```typescript
export interface User {
  id: number;              // PostgreSQL backend ID (use for all requests)
  fullName: string;
  email: string;
  role: 'DOCTOR' | 'PATIENT';
  phoneNumber?: string | null;
  dateOfBirth?: string | null;  // YYYY-MM-DD
  gender?: 'MALE' | 'FEMALE' | null;
  profileImageUrl?: string | null; // base64 URI
}

export interface PatientResponse {
  id: number;
  fullName: string;
  email: string;
  priority: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'NORMAL' | 'LOW';
  healthStatus: 'CRITICAL' | 'WARNING' | 'NORMAL' | 'UNKNOWN';
  profileImageUrl?: string | null;
  gender?: string | null;
  dateOfBirth?: string | null;
  height?: number | null;
  weight?: number | null;
}

export interface HealthMetric {
  id: number;
  heartRate?: number | null;
  spo2?: number | null;
  batteryLevel?: number | null;
  measuredAt?: string | null;   // ISO datetime
  critical: boolean;           // Backend key is 'critical'
  priority?: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'NORMAL' | 'LOW' | null;
  healthStatus?: 'CRITICAL' | 'WARNING' | 'NORMAL' | 'UNKNOWN' | null;
}

export interface Appointment {
  id?: number | null;
  doctorId: number;
  doctorName: string;
  patientId: number;
  patientName: string;
  appointmentDate: string;
  reason?: string | null;
  status: 'SCHEDULED' | 'CONFIRMED' | 'CANCELLED' | 'COMPLETED';
}

export interface ChatMessage {
  senderId: number;
  receiverId: number;
  content: string;
  timestamp?: string | null;
  read: boolean;               // Backend key is 'read'
  delivered: boolean;          // Backend key is 'delivered'
}
```

---

## 9. Design System Summary (Color Tokens & Styles)

Implement these design tokens within the core CSS system (`/styles/globals.css` or equivalent):

### Dashboard Core Color Tokens
```css
:root {
  --color-primary-blue: #407bff;   /* Brand color */
  --color-secondary-blue: #00b4d8; /* Accent/cyan */
  --color-dark-blue: #03045e;      /* Contrast headers */
  --color-background: #f8fafc;     /* Workspace canvas */
  --color-white: #ffffff;
  --color-grey: #94a3b8;
  --color-light-grey: #e2e8f0;
  --color-accent-teal: #00bfa5;    /* Safe status color */
  --color-error: #e53935;          /* Critical status color */
  
  --gradient-primary: linear-gradient(135deg, #407bff, #00b4d8);
  --shadow-card: 0 8px 20px rgba(64, 123, 255, 0.08);
}
```

### Vitals & AI Report Color Tokens
```css
:root {
  --ai-primary: #407bff;
  --ai-primary-surface: #ebf1ff;
  --ai-background: #f0f5ff;
  
  /* Status alert levels */
  --status-success: #10b981;
  --status-warning: #f59e0b;
  --status-danger: #ef4444;
}
```

### Responsive Web Breakpoints
- **Mobile / Portrait**: Up to 768px (collapses sidebar to standard hamburger / bottom navigation).
- **Tablet / Small Desktop**: 768px to 1200px.
- **Large Desktop**: 1200px+ (activates side-by-side master-detail layouts).

### Typography / Font Families
- **Primary App Font**: `Roboto` (or standard system sans-serif fallback). Sourced from main auth/dashboard views.
- **Specialty/AI Report Font**: `Cairo` (premium Google Font, highly optimized for Arabic/Latin readability, used in all AI report viewports, headers, and assessments).

---


## 10. Component Inventory Summary

Build these reusable components for doctor workflows:
1. **Sidebar Navigation**: Desktop navigation menu containing shortcuts for Dashboard, Patients, Chats, Appointments, Profile, Settings. Includes dynamic alerts and badge indicators.
2. **StatCard**: 2-column or grid card containing metric details, icons, and dynamic tap triggers.
3. **PatientCard**: Card component showing patient name, email, priority status badge (color-coded), live heart rate (blinking pulse animation when updating), and quick action buttons (chat shortcut, remove shortcut).
4. **VitalCard**: High-contrast, detailed vital displays for heart rate, blood oxygen, battery levels, and follow-up data.
5. **AssignPatientModal**: Drawer or modal component handling the debounced lookup and association of new patients.
6. **ActiveChatWidget**: Split layout messaging window. Includes message bubble layouts, timestamp dividers, receipt checks, and scrolling management.
7. **InteractiveChart**: Responsive charting wrapper utilizing SVG/HTML5 canvas libraries to support data range views (24H / 7D / 30D).
8. **ToastManager**: Custom notification alert banners that slide down from the header bar, playing audio tags on warning alerts.

---

## 11. Assets to Copy
Copy the primary brand logo file located in the root of the project to your assets directory:
- **Handoff Logo Source**: `app-logo.png` (located at workspace root). Save as `/public/assets/images/logo.png` or equivalent path in the web build.

---

## 12. Environment Variables

Create `.env.local` inside the new web app directory:

```env
# Spring Boot API URL
NEXT_PUBLIC_API_URL=http://smart-medical-api-env.eba-jxdmccmi.us-east-1.elasticbeanstalk.com/api

# STOMP WebSocket Server URL (without http/ws protocol prefix)
NEXT_PUBLIC_WS_HOST=smart-medical-api-env.eba-jxdmccmi.us-east-1.elasticbeanstalk.com
```

---

## 13. Recommended Web Architecture

```
/src
  ├── /components      # Shell layouts, Modals, StatCards, PatientCards, Chart components
  ├── /context         # AuthContext, WebSocketContext
  ├── /hooks           # useWebSocket, usePresence, useInfiniteScroll
  ├── /services        # Axios config (apiClient.ts), ChatService, PresenceService
  ├── /store           # Zustand stores for active state caching (patients, chat, activeId)
  └── /types           # Strong TS definitions matching the PostgreSQL backend
```

---

## 14. Implementation Phases

- **Phase 1: Project Setup**: Initialize Next.js app, configure styling variables, and build the custom Axios client with automatic credential-based token refresh.
- **Phase 2: Authentication & Layout**: Build login/register views and layout wrappers (responsive sidebar + notification header).
- **Phase 3: Core Dashboard & List**: Render stats grids, alert components, patient directories, and the patient assignment lookup drawer.
- **Phase 4: Chats & STOMP integration**: Integrate the WebSocket connection manager. Bind presence checks, chats master lists, and active messaging panes.
- **Phase 5: Patient Details & Reports**: Code vitals summaries, historic charts, and the AI assessment report viewport.
- **Phase 6: Appointments & Notifications**: Schedule calendars, confirm states optimistically, and manage paginated system notifications.

---

## 15. Testing Checklist

- [ ] **Interceptors check**: Verify 401 response from endpoint triggers re-login using stored email + password, then retries original request transparently.
- [ ] **Role protection**: Verify patient login attempt is blocked with an explicit warning "This portal is for doctors only."
- [ ] **WebSocket auto-reconnect**: Verify connection auto-retries every 5s on server disconnect.
- [ ] **Vitals charts**: Switch toggles (24H/7D/30D) and ensure correct endpoint triggers (`/summary/hourly` vs `/summary`).
- [ ] **Receipt marks**: Verify opening a chat triggers read PUT calls and clears corresponding chat notifications.
- [ ] **Data formatting**: Confirm date of birth format is strictly YYYY-MM-DD (no time components) on register.

---

## 16. Missing Info / Risks

1. **Google Sign-In Reconcile**: Google logins on the mobile app generate passwords based on Firebase UID strings. Discuss with the backend team how to register or log in web OAuth users (e.g., using Google client IDs) without using a client-side Firebase Auth layer.
2. **AI Consult Gateway Timeouts**: The AI endpoint has a long processing delay (up to 6 minutes). Ensure the proxy server (e.g., Next.js rewrite or cloud gateway) does not drop the socket. Provide a polling backup via `/ai/history/{patientId}`.
3. **Presence Heartbeat Management**: Ensure the heartbeat PUT call runs strictly while the window is active and active websocket listeners exist. Disconnect on window unload to prevent offline doctors from showing as online.
