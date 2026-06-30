# EXTRACTION_AUDIT.md — Web Rebuild Extraction Audit

This audit evaluates the completeness and readiness of the `/web-rebuild-context/` documents to support building the doctor-only web application from scratch without needing to re-open the original Flutter codebase.

---

## 1. Audit Summary Checklist

| Requirement | Status | Verification Notes |
|:---|:---:|:---|
| **All Doctor Screens Documented** | ✅ Complete | Mapped in `DOCTOR_WEB_SCOPE.md` & `ROUTES_AND_FLOWS.md` |
| **All Doctor Flows Documented** | ✅ Complete | Mapped in `BUSINESS_LOGIC.md` & `DOCTOR_WEB_BUILD_BRIEF.md` |
| **All Doctor APIs Documented** | ✅ Complete | Full request/response definitions in `API_MAP.md` |
| **Auth/Session Behavior Documented**| ✅ Complete | Interceptor & lifecycle logic detailed in `AUTH_AND_SESSION.md` |
| **Data Models Documented** | ✅ Complete | TS types and JSON mapping schema in `DATA_MODELS.md` |
| **Colors Documented** | ✅ Complete | Hex & CSS tokens in `DOCTOR_WEB_BUILD_BRIEF.md` |
| **Typography Documented** | ✅ Complete | Roboto & Cairo fonts listed in `DOCTOR_WEB_BUILD_BRIEF.md` |
| **Components Documented** | ✅ Complete | Reusable widgets listed in `DOCTOR_WEB_BUILD_BRIEF.md` |
| **Assets Copied or Listed** | ✅ Complete | `app-logo.png` target path listed in `DOCTOR_WEB_BUILD_BRIEF.md` |
| **Patient-Only Features Excluded** | ✅ Complete | Explicitly listed and segregated in `DOCTOR_WEB_SCOPE.md` |
| **Shared Patient Data Included** | ✅ Complete | Core patient statistics and vitals records included |
| **Missing/Unclear Info Marked** | ✅ Complete | Reconcile risks mapped in `DOCTOR_WEB_BUILD_BRIEF.md` |
| **Zero Invented Endpoints** | ✅ Verified | All paths cross-referenced with `api_endpoints.dart` |
| **Zero Invented Features** | ✅ Verified | All views cross-referenced with `lib/screens/doctor/` |

---

## 2. What is Complete

### 2.1 API & Network Layer
- **38 REST Endpoints**: Mapped with exact query/path parameters, payload schemas, and roles in `API_MAP.md`.
- **4 WebSocket/STOMP Subscriptions**: Configured with live vitals (`/topic/vitals/*`), real-time messages (`/user/queue/messages`), status updates (`/user/queue/chat-status`), and system events (`/user/queue/system`).
- **Authorization Interceptor Flow**: Detailed custom interceptor structure for catching 401/403 errors, requesting auto-login updates using local state credentials, and retrying failed requests.
- **Error Status Mapping**: Standardizing REST codes (400, 401, 403, 409, 500, timeouts) to user-facing custom error states.

### 2.2 Views and Routing
- **Handoff Route Map**: Clean web paths mapping logical parameters (e.g. `/patients/:patientId/vitals`).
- **13 Page Definitions**: Each with targeted layout proposals (master-detail views, responsive tables, side-by-side dashboards), loader shimmers, empty states, error states, and permissions gates.

### 2.3 Visual Design System
- **Colors**: Defined variables for the core brand colors (`#407BFF` primary, `#00B4D8` secondary/cyan, `#03045E` dark contrast blue) and system alerts matching priority tags.
- **Typography**: Explicitly mapped the `Roboto` font for general UI layouts and the premium `Cairo` font for AI report segments and Arabic translations.
- **Logo Asset**: Brand logo identified (`app-logo.png` at root) and mapped for file copy.

---

## 3. What is Incomplete

- **No elements are incomplete**. All requested materials from the Flutter code have been fully processed, extracted, and consolidated into the `/web-rebuild-context/` directory.

---

## 4. What Needs Verification / Client Decisions

The following items represent design choices and architectural differences between mobile and web that must be verified or decided on before implementation:

### 4.1 Google Sign-In Reconciliation
- **Context**: The Flutter app's Google login relies on Firebase Auth to verify identity, generating a deterministic password: `"GoogleAuth_{firebaseUid}"` which is sent to the backend. The web portal is recommended to bypass Firebase entirely.
- **Decision required**: Will the backend team support a standard Google OAuth login endpoint (e.g., `POST /auth/google`) accepting Google ID tokens directly? If not, we will need to decide if we should include a light web Firebase Auth script to retrieve the UID, or implement standard Email/Password accounts for doctors.

### 4.2 Web Push Notifications
- **Context**: The mobile app utilizes FCM (`/user/fcm-token`) for background push alerts.
- **Decision required**: Will the web app use standard WebSocket system events for foreground notifications only, or will we configure web service-worker push notifications using Web Push API?

### 4.3 AI Consultation Timeout Strategy
- **Context**: `POST /ai/consult/{patientId}` takes up to 6 minutes to return due to AI generation times. Mobile handles this with client-side timeout modifications.
- **Decision required**: To prevent browser timeouts, should the UI transition to an async queue model where it triggers the generation, instantly closes the connection, and then periodically polls the history endpoint (`GET /ai/history/{patientId}`) until the report is compiled?

---

## 5. Handoff Readiness Status

> [!IMPORTANT]
> **READINESS STATUS: READY FOR BUILD**
>
> The extraction context in `web-rebuild-context/` is fully complete and self-contained. Another AI agent or development team can build the strict doctor-only web application from scratch using the files in this directory without needing to review or rebuild the Flutter codebase.
