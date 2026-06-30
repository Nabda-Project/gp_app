# BUSINESS_LOGIC.md — Backend-Dependent Business Logic

> **Source of truth:** Extracted from Flutter services, screens, and interceptors. Documents every piece of business logic that depends on the backend and must be replicated in the web app.

---

## 1. Authentication & Session Lifecycle

### 1.1 Hybrid Auth Flow (Flutter-Specific — Simplify for Web)

**Source:** [`auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart)

The Flutter app uses Firebase Auth + Backend JWT in tandem. On the web, **skip Firebase entirely** and use only the backend JWT.

**Registration order matters:**
1. Backend first (`POST /auth/register`) — this is the source of truth
2. Firebase second — if Firebase fails but backend succeeds, the user still exists on the backend. Next login will reconcile.

**For web:** Just call `POST /auth/register` → `POST /auth/login` → `GET /user/me`.

### 1.2 Google Sign-In Flow (Needs Redesign for Web)

**Source:** [`auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart#L239)

In Flutter:
1. Google OAuth → Firebase credential → Firebase sign-in
2. Generate deterministic password: `"GoogleAuth_{firebaseUid}"`
3. Try `POST /auth/login` — if succeeds, user already registered (returning user)
4. If login fails — new user, redirect to role selection
5. Role selection calls `POST /auth/register` with chosen role

**For web:**
- You need a different Google OAuth flow since there's no Firebase UID
- **Option A**: Implement Google Sign-In via the Google Identity Services SDK, then use the Google email + a deterministic password based on Google's `sub` (subject) claim
- **Option B**: Ask the backend team to add a `/auth/google` endpoint that accepts a Google OAuth token
- **Important**: The deterministic password `"GoogleAuth_{firebaseUid}"` ties Google users to their Firebase UID. Web users won't have this. Discuss with backend team.

### 1.3 Auto Token Refresh (Critical for Web)

**Source:** [`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L62)

**Logic:**
```
On any API response:
  if statusCode == 401 OR 403:
    if endpoint is /auth/login or /auth/register: → pass error through
    if already refreshing: → pass error through
    if already force-logged-out: → pass error through
    
    try:
      credentials = load stored email + password
      if credentials == null: → force logout
      
      response = POST /auth/login(email, password)
      save new JWT
      retry original request with new JWT
      return retried response
    catch:
      if 401/403: → force logout
      else: → pass error through
```

**Web implementation:**
```typescript
// Axios interceptor example
let isRefreshing = false;
let hasForceLoggedOut = false;

axios.interceptors.response.use(
  response => response,
  async error => {
    const { status, config } = error.response;
    const isAuthEndpoint = config.url.includes('/auth/login') || 
                           config.url.includes('/auth/register');

    if ((status === 401 || status === 403) && 
        !isAuthEndpoint && !isRefreshing && !hasForceLoggedOut) {
      isRefreshing = true;
      try {
        const creds = getStoredCredentials();
        if (!creds) { forceLogout(); return; }
        
        const { data } = await axios.post('/auth/login', creds);
        setJWT(data.token);
        
        config.headers.Authorization = `Bearer ${data.token}`;
        isRefreshing = false;
        return axios(config); // Retry
      } catch (e) {
        isRefreshing = false;
        if (e.response?.status === 401 || e.response?.status === 403) {
          forceLogout();
        }
        throw e;
      }
    }
    throw error;
  }
);
```

### 1.4 Force Logout

**Source:** [`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L172)

**Steps:**
1. Delete JWT token (keep stored credentials for potential re-login)
2. Clear user data from storage
3. Shut down WebSocket connection
4. Sign out of Firebase (skip on web)
5. Show toast: "Session Expired — Your session has expired. Please log in again."
6. Navigate to `/auth`, removing all route history

**Guard:** A `_hasForceLoggedOut` flag prevents multiple concurrent 401s from each triggering a redirect. Reset on successful login.

---

## 2. Splash / App Startup Logic

### 2.1 Startup Sequence

**Source:** [`splash_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/splash/splash_screen.dart#L140)

```
1. Wait 2 seconds (animation)
2. Check Firebase auth state
   └─ No user → Show onboarding
   └─ User exists →
      3. Load local user data
         └─ Missing → Fetch from Firestore
      4. Check stored backend credentials
         └─ Missing → Sign out + onboarding (zombie state)
      5. Check internet connectivity
         └─ No internet → Block with "No Internet" screen
      6. Check server reachability (GET to base URL, 4s timeout)
         └─ Unreachable → Block with "Server Down" screen (retry button)
      7. Proactively refresh JWT (non-blocking failure)
      8. Route by user state:
         └─ Has profile, role=Doctor → /doctor_dashboard
         └─ Has profile, role=Patient, profile complete → /patient_dashboard
         └─ Has profile, role=Patient, profile incomplete → /assessment_welcome
         └─ No profile → /role_selection
```

### 2.2 Profile Completeness Check

**Source:** [`splash_screen.dart` L252](file:///e:/side%20projects/gp_app/lib/screens/splash/splash_screen.dart#L252)

```dart
final profileIncomplete = user.dateOfBirth == null ||
    user.gender == null ||
    user.height == null ||
    user.weight == null;
```

**Patient-only.** If incomplete → redirect to AI assessment welcome screen.

**Web equivalent:**
```typescript
function isProfileComplete(user: User): boolean {
  return user.dateOfBirth != null && 
         user.gender != null && 
         user.height != null && 
         user.weight != null;
}
```

### 2.3 Zombie State Detection

If Firebase auth has a user but no backend credentials exist in secure storage (happens after app reinstall since Firebase auth persists across installs but secure storage doesn't), the app performs a clean sign-out and redirects to onboarding.

**Web equivalent:** If JWT exists in localStorage but is expired and no credentials are in sessionStorage → redirect to login.

---

## 3. Doctor Dashboard Business Logic

### 3.1 Patient List Management

**Source:** [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart)

**Data flow:**
1. On mount: `GET /doctor/patients/{doctorId}` → `List<PatientResponseModel>`
2. Each patient has server-computed `priority` and `healthStatus`
3. Real-time vitals updates arrive via WebSocket `/topic/vitals/{doctorId}`

**Refresh triggers:**
- Pull-to-refresh
- After assigning a new patient
- After removing a patient
- System event via WebSocket (patient assignment notification)

### 3.2 Patient Search & Assignment

**Source:** [`doctor_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/doctor_api_service.dart)

**Flow:**
1. Doctor opens search dialog
2. Searches by name: `GET /doctor/search/name?doctorId=X&name=query`
   OR by phone: `GET /doctor/search/phone?doctorId=X&phone=query`
3. Results show patients NOT yet assigned to this doctor
4. Doctor taps "Add" → `POST /doctor/assign?doctorId=X&patientId=Y`
5. Refresh patient list

**Remove flow:**
1. Doctor removes patient → `DELETE /doctor/remove?doctorId=X&patientId=Y`
2. Refresh patient list

### 3.3 Patient Health Status Display

The backend computes these per patient:

| Field | Values | Source |
|-------|--------|--------|
| `healthStatus` | `CRITICAL`, `WARNING`, `NORMAL`, `UNKNOWN` | Based on latest vitals |
| `priority` | `CRITICAL`, `HIGH`, `MEDIUM`, `LOW` | Based on vitals trend/severity |

The web UI should display these as color-coded badges:
- `CRITICAL` → Red
- `WARNING` → Orange/Yellow
- `NORMAL` → Green
- `UNKNOWN` → Gray

---

## 4. Patient Dashboard Business Logic

### 4.1 Data Loading

**Source:** [`patient_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/patient_dashboard_screen.dart)

On mount, the patient dashboard loads:
1. `GET /iot/latest/{patientId}` — current vitals
2. `GET /iot/summary/{patientId}?days=7` — daily summaries for charts
3. `GET /iot/summary/hourly/{patientId}?hours=24` — hourly summaries for 24H chart
4. `GET /patient/doctor/{patientId}` — assigned doctor info
5. `GET /appointments/patient/{patientId}/next` — next appointment
6. `GET /chat/conversations/{patientId}` — chat overview

### 4.2 IoT Device Connection (Mobile-Only)

The patient dashboard on mobile connects to an IoT wearable via UDP on port 4210. This is entirely mobile-specific and **NOT applicable to web**.

On web, the patient views their latest vitals via the REST API only:
- `GET /iot/latest/{patientId}` for current reading
- `GET /iot/history/{patientId}?days=N` for history
- `GET /iot/summary/{patientId}?days=N` for daily charts
- `GET /iot/summary/hourly/{patientId}?hours=N` for hourly charts

### 4.3 Live Vitals via WebSocket (Doctor Side)

**Source:** [`chat_service.dart`](file:///e:/side%20projects/gp_app/lib/services/chat_service.dart#L230)

Doctors receive real-time vitals updates via WebSocket subscription to `/topic/vitals/{doctorId}`. When a patient's IoT device uploads a reading, the backend broadcasts it to the assigned doctor's topic.

**Payload:** `{ "patientId": int, "heartRate": double, "spo2": double, "batteryLevel": int, ... }`

---

## 5. Chat Business Logic

### 5.1 WebSocket Lifecycle

**Source:** [`chat_service.dart`](file:///e:/side%20projects/gp_app/lib/services/chat_service.dart)

**Initialization:**
1. Called once after login (from dashboard)
2. Connects STOMP over SockJS to `http://{host}/ws`
3. Passes JWT in both STOMP connect headers and WebSocket connect headers
4. Subscribes to 4 destinations (messages, status, system, vitals)
5. Starts presence heartbeat

**Singleton pattern:**
- `ChatService.initialize(userId)` — creates/reuses singleton
- `ChatService.instance` — access running instance
- `ChatService.shutdown()` — dispose on logout

**Reconnection:** Automatic every 5 seconds via STOMP client's built-in `reconnectDelay`.

### 5.2 Message Flow

**Sending:**
1. Check if connected (wait up to 5s if connecting)
2. Send STOMP message to `/app/chat.send` with `ChatMessageModel.toJson()`

**Receiving:**
1. STOMP subscription to `/user/queue/messages`
2. Parse JSON → `ChatMessageModel`
3. If message is for me and from someone else → auto-mark as delivered: `PUT /chat/deliver/{senderId}/{receiverId}`
4. Stream to UI via `StreamController`

### 5.3 Read/Delivered Status

**Read tracking:**
- When user opens a chat screen → `PUT /chat/read/{senderId}/{currentUserId}` (marks all messages from sender as read)
- When notifications are opened for chat type → `PUT /notifications/{userId}/read-chat/{senderId}`

**Delivered tracking:**
- When message received via WebSocket → auto `PUT /chat/deliver/{senderId}/{receiverId}`
- When fetching history → if any undelivered messages from other user exist → mark as delivered

**Status updates via WebSocket:**
- Subscription: `/user/queue/chat-status`
- Payload: `{ "status": "read" | "delivered", "receiverId": int }`
- Used to update message ticks (single tick → delivered, double tick → read)

### 5.4 Conversations List Sorting

**Source:** [`chat_service.dart`](file:///e:/side%20projects/gp_app/lib/services/chat_service.dart#L349)

Client-side sorting by `lastMessageTimestamp` descending (most recent first). Null timestamps sort to the end.

---

## 6. Appointments Business Logic

### 6.1 Scheduling

**Source:** [`appointment_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/appointment_api_service.dart#L11)

- Doctor schedules appointment for a specific patient
- `appointmentDate` sent as UTC ISO 8601: `date.toUtc().toIso8601String()`
- `reason` is optional (omitted from JSON if null or empty)

### 6.2 Status Transitions

| From | To | Who |
|------|----|-----|
| `SCHEDULED` | `CONFIRMED` | Doctor |
| `SCHEDULED` | `CANCELLED` | Doctor |
| `CONFIRMED` | `COMPLETED` | Doctor |
| `CONFIRMED` | `CANCELLED` | Doctor |
| `SCHEDULED` | `COMPLETED` | Doctor |

### 6.3 Patient's Next Appointment

- `GET /appointments/patient/{patientId}/next` → returns single `AppointmentModel` or null
- `204 No Content` → no upcoming appointment
- Displayed on patient dashboard as a card

### 6.4 DateTime Handling

**Appointment date parsing quirk:**
The backend may return `appointmentDate` without the `Z` suffix. The Flutter model appends `Z` if missing:
```dart
DateTime.parse(json['appointmentDate'].toString().endsWith('Z')
    ? json['appointmentDate']
    : '${json['appointmentDate']}Z')
```

**Web note:** Handle this in your model parser — append `Z` if the string doesn't end with `Z` to ensure UTC parsing.

---

## 7. Notifications Business Logic

### 7.1 Push Notification System

**Source:** [`push_notification_service.dart`](file:///e:/side%20projects/gp_app/lib/services/push_notification_service.dart)

The Flutter app uses Firebase Cloud Messaging (FCM) for push notifications:
1. Request FCM permission
2. Get FCM device token
3. Register token with backend: `PUT /user/fcm-token` with `{ "token": "..." }`
4. Listen for token refreshes and re-register

**For web:**
- Use the Web Push API or Firebase Cloud Messaging for Web
- Register the web push subscription with the backend
- Alternatively, rely on WebSocket system events for real-time notifications

### 7.2 Notification Types & Navigation

**Source:** [`push_notification_service.dart`](file:///e:/side%20projects/gp_app/lib/services/push_notification_service.dart#L342)

| Type | Navigation Target |
|------|------------------|
| `CHAT` | Chat screen with sender (`relatedId` = sender's userId, `relatedName` = sender's name) |
| `APPOINTMENT_*` | Doctor → appointments screen; Patient → already on dashboard |
| Other | No specific navigation |

### 7.3 In-App Notification Display

**Source:** [`notification_service.dart`](file:///e:/side%20projects/gp_app/lib/services/notification_service.dart)

The app shows animated toast overlays for in-app events:
- `showSuccess` — green toast
- `showError` — red toast
- `showWarning` — yellow toast
- `showInfo` — blue toast
- `showHeadsUp` — with sound + haptic feedback, respects notification settings

Toasts auto-dismiss after 4 seconds.

### 7.4 Notification Settings

Notifications can be toggled via `SettingsModel.enableNotifications`. When disabled:
- FCM foreground messages are suppressed
- Heads-up notifications are suppressed
- System push notifications still come through (FCM background handler)

### 7.5 Notification Pagination

`GET /notifications/{userId}?page=0&size=20` — Spring Page format.

The client handles two response formats:
- Paginated: `{ "content": [...], "totalPages": N, ... }`
- Flat list: `[...]`

---

## 8. Presence & Online Status

### 8.1 Heartbeat System

**Source:** [`presence_service.dart`](file:///e:/side%20projects/gp_app/lib/services/presence_service.dart)

- Heartbeat sent every 30 seconds: `PUT /presence/heartbeat/{userId}`
- Started automatically when WebSocket connects
- Stopped when WebSocket disconnects or on logout

### 8.2 Querying Presence

- `GET /presence/{userId}` → `{ online: bool, lastSeen: string? }`
- Called when opening chat screens to show online/offline indicator

### 8.3 Web Implementation Notes

- Start heartbeat interval on login
- Clear interval on logout
- Use `beforeunload`/`pagehide` events to stop heartbeat when tab closes
- Consider using `visibilitychange` to pause heartbeat when tab is hidden

---

## 9. AI Assessment Business Logic

### 9.1 Assessment Flow

**Source:** [`ai_assessment_api.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/data/ai_assessment_api.dart)

1. Patient answers cardiac assessment questionnaire (multi-step form)
2. Questionnaire data is built as a nested JSON object
3. Submit: `POST /ai/consult/{patientId}` with the full assessment JSON
4. **Very long timeout**: Send 30s, Receive **6 minutes** (AI processing)
5. Response contains `aiReport` — a markdown-formatted analysis

### 9.2 Question Structure

**Source:** [`assessment_models.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/models/assessment_models.dart), [`cardiac_questions.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/data/cardiac_questions.dart)

Questions have:
- `field` — JSON path for the answer (e.g., `"demographics.age"`)
- `type` — `number`, `choice`, `multiChoice`, `text`
- `options` — for choice/multiChoice types
- `dependsOn` — conditional visibility based on previous answers
- `hasNoneOption` — multi-choice with "None" toggle

### 9.3 Report History

- Patient views own reports: `GET /ai/my-reports`
- Doctor views patient's reports: `GET /ai/history/{patientId}`
- Reports contain:
  - `patientInput` — stringified JSON of the assessment answers
  - `aiReport` — markdown AI analysis
  - `createdAt` — timestamp
  - Patient demographics at time of submission

---

## 10. Profile Management

### 10.1 Profile Update

**Source:** [`profile_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/profile/profile_screen.dart)

`PUT /user/me` with a partial object. Only non-null fields are sent.

### 10.2 Profile Image

**Source:** [`profile_screen.dart` L89](file:///e:/side%20projects/gp_app/lib/screens/profile/profile_screen.dart#L89)

- Images are sent as Base64 data URIs in the `profileImageUrl` field
- Format: `"data:image/jpeg;base64,/9j/4AAQ..."` (or png, etc.)
- To remove image: send `profileImageUrl: ""`
- No separate file upload endpoint

**For web:**
- Use `FileReader.readAsDataURL()` to convert selected file to data URI
- Send the full data URI string in `PUT /user/me`
- Be aware of request size limits — large images may fail

### 10.3 Password Change

Password can be updated via `PUT /user/me` with `{ "password": "newPassword" }`.

After changing password:
- Update stored credentials for auto-refresh
- Backend JWT continues to work until it expires

---

## 11. Localization

### 11.1 Supported Languages

**Source:** [`app_localizations.dart`](file:///e:/side%20projects/gp_app/lib/utils/app_localizations.dart)

| Code | Language |
|------|----------|
| `en` | English |
| `ar` | Arabic (RTL) |

### 11.2 Storage

Language preference stored in `SettingsModel.languageCode` (Hive local storage).

For web: Store in `localStorage` and apply on page load.

---

## 12. Error Handling Patterns

### 12.1 Service-Level Error Handling

All API services follow the same pattern:

```dart
try {
  final response = await DioClient.instance.get(endpoint);
  return ModelClass.fromJson(response.data);
} on DioException catch (e) {
  if (e.error is ApiException) throw e.error!;
  rethrow;
}
```

**Translation for web:**
```typescript
try {
  const response = await apiClient.get(endpoint);
  return response.data;
} catch (error) {
  if (axios.isAxiosError(error)) {
    const apiError = mapHttpError(error.response?.status, error.response?.data);
    throw apiError;
  }
  throw error;
}
```

### 12.2 Graceful Null Handling

Several endpoints return 204 No Content for "not found" scenarios (not 404):
- `GET /patient/doctor/{id}` → 204 if no doctor assigned
- `GET /appointments/patient/{id}/next` → 204 if no upcoming appointment
- `GET /iot/latest/{id}` → 404 if no readings exist

**Pattern:** Check for `204 || response.data == null` → return `null`.

### 12.3 Non-Critical Error Swallowing

These operations silently catch errors (non-critical):
- Firestore save (skip on web)
- FCM token registration
- Notification marking as read/delivered
- Presence heartbeat
- Chat history fetch (returns empty list on error)
- Conversations fetch (returns empty list on error)

---

## 13. Real-Time Data Flow Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    WEBSOCKET EVENTS                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  /user/queue/messages     → New chat messages                │
│  /user/queue/chat-status  → Read/delivered receipts          │
│  /user/queue/system       → Patient assignment events        │
│  /topic/vitals/{doctorId} → Live patient vitals (doctor)     │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                    STOMP DESTINATIONS                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  /app/chat.send           → Send chat message                │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                    PERIODIC REST CALLS                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  PUT /presence/heartbeat  → Every 30 seconds                 │
│  POST /iot/upload         → Every 1 second (mobile BG only)  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 14. Critical Business Rules Summary

| Rule | Source | Impact |
|------|--------|--------|
| Backend ID is needed for ALL API calls | `backendId` from `/user/me` | Must call `/user/me` right after login |
| No refresh token — re-login to refresh | Dio interceptor | Store credentials for auto-refresh |
| Force logout on failed refresh | Dio interceptor | Single guard prevents duplicate logouts |
| 204 = empty (not error) | Patient doctor, next appointment | Return null, don't throw |
| Priority/healthStatus computed server-side | PatientResponseModel | Don't compute on client |
| Auto-mark messages as delivered | ChatService | Call on WebSocket receive + history fetch |
| Heartbeat starts on WebSocket connect | PresenceService | Start/stop with WS lifecycle |
| AI assessment has 6-min timeout | AiAssessmentApiService | Show progress indicator, allow cancel |
| Profile image is Base64 in field | UserApiService | No file upload endpoint |
| `dateOfBirth` format is `YYYY-MM-DD` only | RegisterRequest | Not ISO 8601 with time |
| Appointment dates may lack `Z` suffix | AppointmentModel | Append `Z` if missing |
| `critical` not `isCritical` in JSON | HealthMetricModel | Jackson `is`-prefix convention |
| `read` not `isRead` in JSON | ChatMessageModel, NotificationItem | Same Jackson convention |
| Notification response can be Page or List | NotificationApiService | Handle both formats |
