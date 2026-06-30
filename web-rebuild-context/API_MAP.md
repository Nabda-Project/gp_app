# API_MAP.md — Complete Backend API Reference

> **Source of truth:** Extracted from the Flutter codebase. Every endpoint listed here is actually used in the app.
> Base URL: `http://smart-medical-api-env.eba-jxdmccmi.us-east-1.elasticbeanstalk.com/api`
> WebSocket URL: `ws://smart-medical-api-env.eba-jxdmccmi.us-east-1.elasticbeanstalk.com/ws`
>
> Defined in [`api_config.dart`](file:///e:/side%20projects/gp_app/lib/core/config/api_config.dart)
> All endpoint paths defined in [`api_endpoints.dart`](file:///e:/side%20projects/gp_app/lib/core/api/api_endpoints.dart)

---

## Global HTTP Configuration

| Setting | Value | Source |
|---------|-------|--------|
| Base URL | `http://{host}/api` | [`api_config.dart`](file:///e:/side%20projects/gp_app/lib/core/config/api_config.dart) |
| Content-Type | `application/json` | [`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L32) |
| Accept | `application/json` | [`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L33) |
| Connect Timeout | 15 seconds | [`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L28) |
| Receive Timeout | 15 seconds | [`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L29) |
| Send Timeout | 15 seconds | [`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L30) |
| Auth Header | `Authorization: Bearer <JWT>` | Auto-injected by `_AuthInterceptor` |

### Auth Interceptor Behavior ([`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L62))

- **Public paths** (no token injected): `/auth/login`, `/auth/register`
- **All other paths**: JWT token auto-injected from `TokenService.getToken()`
- **On 401/403 (non-auth endpoints)**: Auto-refreshes by re-logging in with stored credentials, then retries the original request
- **If refresh fails**: Force logout → clear token → sign out Firebase → navigate to `/auth`
- **Force-logout guard**: Prevents multiple concurrent 401s from triggering multiple redirects

### Error Mapping ([`api_exceptions.dart`](file:///e:/side%20projects/gp_app/lib/core/api/api_exceptions.dart))

| HTTP Status | Exception Class | Default Message |
|-------------|----------------|-----------------|
| 400 / 422 | `ValidationException` | "Invalid data provided." |
| 401 | `UnauthorizedException` | "Session expired. Please log in again." |
| 403 | `ForbiddenException` | "You do not have permission for this action." |
| 409 | `ConflictException` | "Resource already exists." |
| 500 | `ServerException` | "An unexpected server error occurred." |
| Timeout | `NetworkException` | "Connection timed out. Please try again." |
| Connection Error | `NetworkException` | "Cannot reach server. Please check your connection." |

> **Error response parsing**: Backend errors come as `{ "message": "..." }` or `{ "error": "..." }` or plain string body.

---

## 1. AUTH — `/api/auth/*`

### 1.1 Register

| Property | Value |
|----------|-------|
| **Feature** | User Registration |
| **Flutter file** | [`backend_auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/backend_auth_service.dart#L18) |
| **Screen / Flow** | [`auth_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/auth/auth_screen.dart) (Sign Up tab), [`role_selection_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/role_selection/role_selection_screen.dart) (Google Sign-In users) |
| **User role** | Shared (both Doctor and Patient) |
| **HTTP method** | `POST` |
| **Endpoint** | `/auth/register` |
| **Auth required** | ❌ No (public path) |
| **Query params** | None |
| **Path params** | None |
| **Request body** | `RegisterRequest.toJson()` — see below |
| **Request headers** | Standard (`Content-Type: application/json`) |
| **Response shape** | `Map<String, dynamic>` — raw `User` entity from backend |
| **Error handling** | `ConflictException` (409) if email exists; DioException rethrown |
| **Loading behavior** | Button shows loading spinner; form disabled during request |
| **Retry behavior** | None (user re-submits manually) |
| **Pagination** | N/A |
| **Related models** | [`RegisterRequest`](file:///e:/side%20projects/gp_app/lib/models/register_request.dart), [`UserModel`](file:///e:/side%20projects/gp_app/lib/models/user_model.dart) |

**Request body:**
```json
{
  "fullName": "string",
  "email": "string",
  "password": "string",
  "phoneNumber": "string",
  "role": "PATIENT" | "DOCTOR",
  "dateOfBirth": "YYYY-MM-DD",
  "gender": "MALE" | "FEMALE",
  "height": 170.0,       // optional, cm (patients only)
  "weight": 70.0          // optional, kg (patients only)
}
```

**Response body (success):**
```json
{
  "id": 1,
  "fullName": "string",
  "name": "string",        // RegisterResponse uses 'name'
  "email": "string",
  "role": "PATIENT" | "DOCTOR",
  "phoneNumber": "string",
  "dateOfBirth": "YYYY-MM-DD",
  "gender": "MALE" | "FEMALE",
  "height": 170.0,
  "weight": 70.0,
  "profileImageUrl": null
}
```

**Notes for web:**
- The Flutter app sends `dateOfBirth` formatted as `YYYY-MM-DD` (not ISO 8601 with time).
- `role` must be uppercase: `"PATIENT"` or `"DOCTOR"` (the Flutter UI shows title-case "Patient"/"Doctor" but converts before sending).
- `height` and `weight` are only sent for patients (omitted from JSON if null).
- On the web, you don't need Firebase Auth. Register directly with the backend.

---

### 1.2 Login

| Property | Value |
|----------|-------|
| **Feature** | User Login |
| **Flutter file** | [`backend_auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/backend_auth_service.dart#L38) |
| **Screen / Flow** | [`auth_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/auth/auth_screen.dart) (Sign In tab), token refresh interceptor, splash screen auto-login |
| **User role** | Shared |
| **HTTP method** | `POST` |
| **Endpoint** | `/auth/login` |
| **Auth required** | ❌ No (public path) |
| **Query params** | None |
| **Path params** | None |
| **Request body** | `LoginRequest.toJson()` |
| **Request headers** | Standard |
| **Response shape** | `AuthResponse` |
| **Error handling** | `UnauthorizedException` (401) if credentials invalid |
| **Loading behavior** | Button loading spinner |
| **Retry behavior** | Auto-retry by Dio interceptor on 401 for non-auth requests |
| **Related models** | [`LoginRequest`](file:///e:/side%20projects/gp_app/lib/models/login_request.dart), [`AuthResponse`](file:///e:/side%20projects/gp_app/lib/models/auth_response.dart) |

**Request body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response body (success):**
```json
{
  "token": "jwt-string"
}
```

**Notes for web:**
- The JWT has no refresh token mechanism. When it expires, the app re-logs in using stored credentials.
- For web, store the JWT in `localStorage` or `httpOnly` cookie. Store email/password in `sessionStorage` (or equivalent) for auto-refresh.
- Google Sign-In users use a deterministic password: `"GoogleAuth_{firebaseUid}"`. On web, implement Google OAuth differently — see AUTH_AND_SESSION.md.

---

## 2. USER — `/api/user/*`

### 2.1 Get Current User Profile

| Property | Value |
|----------|-------|
| **Feature** | Fetch authenticated user's profile |
| **Flutter file** | [`backend_auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/backend_auth_service.dart#L59) |
| **Screen / Flow** | Called after login to populate `backendId` and role; called in [`auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart#L202) |
| **User role** | Shared |
| **HTTP method** | `GET` |
| **Endpoint** | `/user/me` |
| **Auth required** | ✅ Yes (JWT Bearer) |
| **Query params** | None |
| **Path params** | None |
| **Request body** | None |
| **Response shape** | `Map<String, dynamic>` |
| **Error handling** | Standard DioException → ApiException mapping |
| **Related models** | [`UserModel`](file:///e:/side%20projects/gp_app/lib/models/user_model.dart) (built via `fromBackendJson` or manual field extraction) |

**Response body:**
```json
{
  "id": 1,
  "fullName": "string",
  "email": "string",
  "role": "PATIENT" | "DOCTOR",
  "phoneNumber": "string" | null,
  "dateOfBirth": "YYYY-MM-DD" | null,
  "gender": "MALE" | "FEMALE" | null,
  "height": 170.0 | null,
  "weight": 70.0 | null,
  "profileImageUrl": "string" | null
}
```

**Notes for web:**
- This is the primary endpoint for determining the current user's role and backend ID.
- Call immediately after login to populate the session context.
- `role` values from backend are uppercase (`DOCTOR`/`PATIENT`); the Flutter app normalizes to title-case for display.

---

### 2.2 Update User Profile

| Property | Value |
|----------|-------|
| **Feature** | Edit profile fields |
| **Flutter file** | [`user_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/user_api_service.dart#L18) |
| **Screen / Flow** | [`profile_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/profile/profile_screen.dart) |
| **User role** | Shared |
| **HTTP method** | `PUT` |
| **Endpoint** | `/user/me` |
| **Auth required** | ✅ Yes |
| **Query params** | None |
| **Path params** | None |
| **Request body** | Partial map with any of the updatable fields |
| **Response shape** | `Map<String, dynamic>` — updated user object |
| **Error handling** | Standard ApiException mapping |

**Request body (partial — only non-null fields sent):**
```json
{
  "fullName": "string",
  "phoneNumber": "string",
  "email": "string",
  "password": "string",
  "dateOfBirth": "YYYY-MM-DD",
  "gender": "MALE" | "FEMALE",
  "height": 170.0,
  "weight": 70.0,
  "profileImageUrl": "data:image/jpeg;base64,..." | ""
}
```

**Notes for web:**
- Profile image is stored as a Base64 data URI string directly in the `profileImageUrl` field. No separate file upload endpoint.
- Sending an empty string `""` for `profileImageUrl` removes the image.
- The backend returns the full updated user object.

---

### 2.3 Update FCM Token

| Property | Value |
|----------|-------|
| **Feature** | Register push notification token |
| **Flutter file** | [`push_notification_service.dart`](file:///e:/side%20projects/gp_app/lib/services/push_notification_service.dart#L215) |
| **Screen / Flow** | Called automatically during `PushNotificationService.initialize()` after login |
| **User role** | Shared |
| **HTTP method** | `PUT` |
| **Endpoint** | `/user/fcm-token` |
| **Auth required** | ✅ Yes |
| **Request body** | `{ "token": "fcm-device-token-string" }` |
| **Response shape** | Not used by client |
| **Error handling** | Silently caught — non-critical |

**Notes for web:**
- Web push notifications may use a different mechanism (Web Push API / service worker).
- If implementing web push, register the web push subscription endpoint here instead of FCM token.
- Endpoint may need backend support for web push tokens — verify with backend team.

---

## 3. DOCTOR — `/api/doctor/*`

### 3.1 Assign Patient to Doctor

| Property | Value |
|----------|-------|
| **Feature** | Link a patient to this doctor |
| **Flutter file** | [`doctor_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/doctor_api_service.dart#L16) |
| **Screen / Flow** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — search result → "Add" button |
| **User role** | Doctor only |
| **HTTP method** | `POST` |
| **Endpoint** | `/doctor/assign` |
| **Auth required** | ✅ Yes |
| **Query params** | `doctorId: int`, `patientId: int` |
| **Path params** | None |
| **Request body** | None |
| **Response type** | `ResponseType.bytes` (empty body expected) |
| **Error handling** | Standard ApiException |

**Notes for web:**
- Query params, not body! `POST /doctor/assign?doctorId=1&patientId=2`
- Response body is empty (the Flutter client uses `ResponseType.bytes` to handle this).

---

### 3.2 Get Assigned Patients

| Property | Value |
|----------|-------|
| **Feature** | List all patients linked to a doctor |
| **Flutter file** | [`doctor_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/doctor_api_service.dart#L41) |
| **Screen / Flow** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — patient list |
| **User role** | Doctor only |
| **HTTP method** | `GET` |
| **Endpoint** | `/doctor/patients/{doctorId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `doctorId: int` |
| **Query params** | None |
| **Response shape** | `List<PatientResponseModel>` |
| **Error handling** | Standard ApiException |
| **Loading behavior** | Shimmer/skeleton loading in dashboard |

**Response body:**
```json
[
  {
    "id": 1,
    "fullName": "string",
    "email": "string",
    "priority": "LOW" | "MEDIUM" | "HIGH" | "CRITICAL",
    "healthStatus": "NORMAL" | "WARNING" | "CRITICAL" | "UNKNOWN",
    "profileImageUrl": "string" | null,
    "gender": "MALE" | "FEMALE" | null,
    "dateOfBirth": "YYYY-MM-DD" | null,
    "height": 170.0 | null,
    "weight": 70.0 | null
  }
]
```

**Notes for web:**
- The `priority` and `healthStatus` fields are computed server-side based on the patient's latest vitals.
- `healthStatus` enum values: `CRITICAL`, `WARNING`, `NORMAL`, `UNKNOWN`.
- `priority` enum values: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW` (+ `NORMAL` seen in HealthMetricModel).

---

### 3.3 Search Patients by Name

| Property | Value |
|----------|-------|
| **Feature** | Search unassigned patients by name |
| **Flutter file** | [`doctor_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/doctor_api_service.dart#L66) |
| **Screen / Flow** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — search dialog |
| **User role** | Doctor only |
| **HTTP method** | `GET` |
| **Endpoint** | `/doctor/search/name` |
| **Auth required** | ✅ Yes |
| **Query params** | `doctorId: int`, `name: string` |
| **Response shape** | `List<PatientSearchModel>` |

**Response body:**
```json
[
  {
    "id": 1,
    "fullName": "string",
    "email": "string",
    "phoneNumber": "string" | null
  }
]
```

**Notes for web:**
- Returns patients NOT yet assigned to this doctor.

---

### 3.4 Search Patients by Phone

| Property | Value |
|----------|-------|
| **Feature** | Search unassigned patients by phone number |
| **Flutter file** | [`doctor_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/doctor_api_service.dart#L101) |
| **Screen / Flow** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — search dialog |
| **User role** | Doctor only |
| **HTTP method** | `GET` |
| **Endpoint** | `/doctor/search/phone` |
| **Auth required** | ✅ Yes |
| **Query params** | `doctorId: int`, `phone: string` |
| **Response shape** | `List<PatientSearchModel>` |

---

### 3.5 Remove Patient from Doctor

| Property | Value |
|----------|-------|
| **Feature** | Unlink a patient from this doctor |
| **Flutter file** | [`doctor_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/doctor_api_service.dart#L135) |
| **Screen / Flow** | [`doctor_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_dashboard_screen.dart) — patient list swipe/delete |
| **User role** | Doctor only |
| **HTTP method** | `DELETE` |
| **Endpoint** | `/doctor/remove` |
| **Auth required** | ✅ Yes |
| **Query params** | `doctorId: int`, `patientId: int` |
| **Request body** | None |
| **Response type** | `ResponseType.bytes` (empty body) |

---

## 4. PATIENT — `/api/patient/*`

### 4.1 Get Assigned Doctor

| Property | Value |
|----------|-------|
| **Feature** | Get the doctor assigned to a patient |
| **Flutter file** | [`patient_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/patient_api_service.dart#L18) |
| **Screen / Flow** | [`patient_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/patient_dashboard_screen.dart) — doctor info card |
| **User role** | Patient only |
| **HTTP method** | `GET` |
| **Endpoint** | `/patient/doctor/{patientId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `patientId: int` |
| **Response shape** | `DoctorInfoModel` or `null` (204 No Content) |

**Response body (200):**
```json
{
  "id": 1,
  "fullName": "Dr. Smith",
  "email": "doctor@email.com",
  "profileImageUrl": "string" | null
}
```

**Notes for web:**
- Returns `204 No Content` with null/empty body if no doctor is assigned.
- Handle both 204 status and null response data.

---

## 5. IoT / HEALTH METRICS — `/api/iot/*`

### 5.1 Upload Health Metric

| Property | Value |
|----------|-------|
| **Feature** | Upload a sensor reading to backend |
| **Flutter file** | [`iot_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/iot_api_service.dart#L18), [`health_monitor_service.dart`](file:///e:/side%20projects/gp_app/lib/services/health_monitor_service.dart#L418) |
| **Screen / Flow** | Background foreground service (automatic every 1 second when device connected) |
| **User role** | Patient (data uploaded for patient's ID) |
| **HTTP method** | `POST` |
| **Endpoint** | `/iot/upload/{patientId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `patientId: int` |
| **Request body** | `MetricRequest.toJson()` |
| **Response shape** | `HealthMetricModel` |

**Request body:**
```json
{
  "heartRate": 72.5,
  "spo2": 97.0,
  "batteryLevel": 85
}
```

**Response body:**
```json
{
  "id": 123,
  "heartRate": 72.5,
  "spo2": 97.0,
  "batteryLevel": 85,
  "measuredAt": "2024-01-15T10:30:00",
  "critical": false,
  "priority": "NORMAL",
  "healthStatus": "NORMAL"
}
```

**Notes for web:**
- This is primarily used by the mobile app's background service (reads from IoT device via UDP).
- On web, this endpoint is unlikely to be called directly unless you implement a simulated device or manual entry.
- The background service has its own token refresh mechanism independent of the main app.

---

### 5.2 Get Latest Metric

| Property | Value |
|----------|-------|
| **Feature** | Get the most recent health reading for a patient |
| **Flutter file** | [`iot_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/iot_api_service.dart#L39) |
| **Screen / Flow** | [`patient_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/patient_dashboard_screen.dart), [`patient_detail_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_detail_screen.dart) |
| **User role** | Shared (patient sees own, doctor sees patient's) |
| **HTTP method** | `GET` |
| **Endpoint** | `/iot/latest/{patientId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `patientId: int` |
| **Response shape** | `HealthMetricModel` or `null` |

**Notes for web:**
- Returns `404` if no readings exist — the Flutter client returns `null` gracefully on 404.

---

### 5.3 Get Metric History

| Property | Value |
|----------|-------|
| **Feature** | Get historical health readings for a patient |
| **Flutter file** | [`iot_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/iot_api_service.dart#L66) |
| **Screen / Flow** | [`patient_vitals_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_vitals_screen.dart), [`vitals_history_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/vitals_history_screen.dart), [`medical_history_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/medical_history_screen.dart) |
| **User role** | Shared |
| **HTTP method** | `GET` |
| **Endpoint** | `/iot/history/{patientId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `patientId: int` |
| **Query params** | `days: int` (default `7`) |
| **Response shape** | `List<HealthMetricModel>` |
| **Sorting** | Newest first (backend orders by timestamp DESC) |

---

### 5.4 Get Daily Summary

| Property | Value |
|----------|-------|
| **Feature** | Daily aggregated metrics for charting |
| **Flutter file** | [`iot_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/iot_api_service.dart#L92) |
| **Screen / Flow** | Charts in patient dashboard, patient detail screen |
| **User role** | Shared |
| **HTTP method** | `GET` |
| **Endpoint** | `/iot/summary/{patientId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `patientId: int` |
| **Query params** | `days: int` (default `7`) |
| **Response shape** | `List<DailySummaryModel>` |
| **Sorting** | Oldest first (ascending by date) |

**Response body:**
```json
[
  {
    "date": "2024-01-15",
    "avgHeartRate": 72.5,
    "avgSpo2": 97.0,
    "minHeartRate": 60.0,
    "maxHeartRate": 85.0,
    "minSpo2": 95.0,
    "maxSpo2": 99.0,
    "readingCount": 150
  }
]
```

---

### 5.5 Get Hourly Summary

| Property | Value |
|----------|-------|
| **Feature** | Hourly aggregated metrics for 24H chart mode |
| **Flutter file** | [`iot_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/iot_api_service.dart#L118) |
| **Screen / Flow** | Charts with 24H toggle |
| **User role** | Shared |
| **HTTP method** | `GET` |
| **Endpoint** | `/iot/summary/hourly/{patientId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `patientId: int` |
| **Query params** | `hours: int` (default `24`) |
| **Response shape** | `List<HourlySummaryModel>` |
| **Sorting** | Oldest first (ascending by dateTime) |

**Response body:**
```json
[
  {
    "dateTime": "2024-01-15T10:00:00",
    "avgHeartRate": 72.5,
    "avgSpo2": 97.0,
    "minHeartRate": 60.0,
    "maxHeartRate": 85.0,
    "minSpo2": 95.0,
    "maxSpo2": 99.0,
    "readingCount": 60
  }
]
```

---

## 6. CHAT — `/api/chat/*` + WebSocket

### 6.1 Get Chat History (REST)

| Property | Value |
|----------|-------|
| **Feature** | Load message history between two users |
| **Flutter file** | [`chat_service.dart`](file:///e:/side%20projects/gp_app/lib/services/chat_service.dart#L302) |
| **Screen / Flow** | [`doctor_chat_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/doctor_chat_screen.dart), [`patient_chat_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_chat_screen.dart) |
| **User role** | Shared |
| **HTTP method** | `GET` |
| **Endpoint** | `/chat/history/{userId1}/{userId2}` |
| **Auth required** | ✅ Yes |
| **Path params** | `userId1: int` (current user), `userId2: int` (other user) |
| **Response shape** | `List<ChatMessageModel>` |
| **Side effect** | After fetching, auto-marks undelivered messages from `otherUserId` as delivered |

**Response body:**
```json
[
  {
    "senderId": 1,
    "receiverId": 2,
    "content": "Hello",
    "timestamp": "2024-01-15T10:30:00",
    "senderName": "Dr. Smith",
    "read": false,
    "delivered": true
  }
]
```

---

### 6.2 Get Conversations List

| Property | Value |
|----------|-------|
| **Feature** | List all chat partners with last message and unread count |
| **Flutter file** | [`chat_service.dart`](file:///e:/side%20projects/gp_app/lib/services/chat_service.dart#L336) |
| **Screen / Flow** | Doctor dashboard chat tab, patient dashboard chat |
| **User role** | Shared |
| **HTTP method** | `GET` |
| **Endpoint** | `/chat/conversations/{userId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `userId: int` (current user's backend ID) |
| **Response shape** | `List<ChatContactModel>` |
| **Client-side sorting** | By `lastMessageTimestamp` descending (most recent first) |

**Response body:**
```json
[
  {
    "partnerId": 2,
    "partnerName": "Patient Name",
    "partnerEmail": "patient@email.com",
    "lastMessage": "Hello doctor",
    "lastMessageTimestamp": "2024-01-15T10:30:00",
    "unreadCount": 3,
    "partnerProfileImageUrl": "string" | null
  }
]
```

---

### 6.3 Mark Messages as Read

| Property | Value |
|----------|-------|
| **Feature** | Mark all messages from sender to receiver as read |
| **Flutter file** | [`chat_service.dart`](file:///e:/side%20projects/gp_app/lib/services/chat_service.dart#L369) |
| **Screen / Flow** | Chat screens — called when user opens/views messages |
| **User role** | Shared |
| **HTTP method** | `PUT` |
| **Endpoint** | `/chat/read/{senderId}/{receiverId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `senderId: int`, `receiverId: int` (current user) |
| **Request body** | None |

---

### 6.4 Mark Messages as Delivered

| Property | Value |
|----------|-------|
| **Feature** | Mark all messages from sender to receiver as delivered |
| **Flutter file** | [`chat_service.dart`](file:///e:/side%20projects/gp_app/lib/services/chat_service.dart#L380) |
| **Screen / Flow** | Auto-called when receiving messages via WebSocket or fetching history |
| **User role** | Shared |
| **HTTP method** | `PUT` |
| **Endpoint** | `/chat/deliver/{senderId}/{receiverId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `senderId: int`, `receiverId: int` (current user) |

---

### 6.5 Send Message (WebSocket/STOMP)

| Property | Value |
|----------|-------|
| **Feature** | Send a real-time chat message |
| **Flutter file** | [`chat_service.dart`](file:///e:/side%20projects/gp_app/lib/services/chat_service.dart#L272) |
| **Protocol** | STOMP over SockJS |
| **Destination** | `/app/chat.send` |
| **Auth** | JWT passed in STOMP connect headers |

**STOMP message body:**
```json
{
  "senderId": 1,
  "receiverId": 2,
  "content": "Hello",
  "read": false,
  "delivered": false
}
```

---

### 6.6 WebSocket Subscriptions

All subscriptions are set up in [`chat_service.dart`](file:///e:/side%20projects/gp_app/lib/services/chat_service.dart#L158).

| Destination | Purpose | Payload shape |
|-------------|---------|---------------|
| `/user/queue/messages` | Incoming chat messages | `ChatMessageModel` JSON |
| `/user/queue/chat-status` | Read/delivered status updates | `{ "status": "read" \| "delivered", "receiverId": int }` |
| `/user/queue/system` | System events (patient assignment, etc.) | `{ "type": "string", ... }` |
| `/topic/vitals/{userId}` | Live vitals updates (doctor sees patient readings) | `{ "patientId": int, ... }` |

**WebSocket connection:**
- URL: `http://{host}/ws` (SockJS)
- Connect headers: `{ "Authorization": "Bearer <JWT>" }`
- Reconnect delay: 5 seconds (automatic)
- Connection timeout: 10 seconds

**Notes for web:**
- Use SockJS client or native WebSocket for STOMP.
- The `/topic/vitals/{userId}` subscription uses the **doctor's** userId — the backend broadcasts patient vitals to the doctor's topic.
- On WebSocket connect, the presence heartbeat starts automatically.

---

## 7. PRESENCE — `/api/presence/*`

### 7.1 Get User Presence

| Property | Value |
|----------|-------|
| **Feature** | Check if a user is online and their last-seen time |
| **Flutter file** | [`presence_service.dart`](file:///e:/side%20projects/gp_app/lib/services/presence_service.dart#L22) |
| **Screen / Flow** | Chat screens — shows online/offline indicator |
| **User role** | Shared |
| **HTTP method** | `GET` |
| **Endpoint** | `/presence/{userId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `userId: int` |
| **Response shape** | `PresenceStatus` |

**Response body:**
```json
{
  "online": true,
  "lastSeen": "2024-01-15T10:30:00" | null
}
```

---

### 7.2 Send Heartbeat

| Property | Value |
|----------|-------|
| **Feature** | Maintain online status |
| **Flutter file** | [`presence_service.dart`](file:///e:/side%20projects/gp_app/lib/services/presence_service.dart#L43) |
| **Screen / Flow** | Automatically started on WebSocket connect; periodic every 30 seconds |
| **User role** | Shared |
| **HTTP method** | `PUT` |
| **Endpoint** | `/presence/heartbeat/{userId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `userId: int` (current user's backendId) |
| **Request body** | None |

**Notes for web:**
- Start heartbeat on login/WebSocket connect.
- Stop on logout or window close.
- Consider using `beforeunload` event to stop heartbeat on web.

---

## 8. APPOINTMENTS — `/api/appointments/*`

### 8.1 Schedule Appointment

| Property | Value |
|----------|-------|
| **Feature** | Create a new appointment |
| **Flutter file** | [`appointment_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/appointment_api_service.dart#L11) |
| **Screen / Flow** | [`doctor_appointments_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_appointments_screen.dart), patient detail screen |
| **User role** | Doctor (primary), but endpoint is shared |
| **HTTP method** | `POST` |
| **Endpoint** | `/appointments/schedule` |
| **Auth required** | ✅ Yes |
| **Request body** | See below |
| **Response shape** | `AppointmentModel` |

**Request body:**
```json
{
  "doctorId": 1,
  "patientId": 2,
  "appointmentDate": "2024-01-20T14:00:00.000Z",
  "reason": "Follow-up checkup"  // optional
}
```

**Notes for web:**
- `appointmentDate` is sent as UTC ISO 8601 string.

---

### 8.2 Get Doctor's Appointments

| Property | Value |
|----------|-------|
| **Feature** | List all appointments for a doctor |
| **Flutter file** | [`appointment_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/appointment_api_service.dart#L35) |
| **Screen / Flow** | [`doctor_appointments_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_appointments_screen.dart) |
| **User role** | Doctor only |
| **HTTP method** | `GET` |
| **Endpoint** | `/appointments/doctor/{doctorId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `doctorId: int` |
| **Response shape** | `List<AppointmentModel>` |

**Response body:**
```json
[
  {
    "id": 1,
    "doctorId": 1,
    "doctorName": "Dr. Smith",
    "patientId": 2,
    "patientName": "John Doe",
    "appointmentDate": "2024-01-20T14:00:00",
    "reason": "Follow-up",
    "status": "SCHEDULED" | "CONFIRMED" | "CANCELLED" | "COMPLETED"
  }
]
```

**Notes for web:**
- `appointmentDate` from backend may or may not have the `Z` suffix. The Flutter model handles both: appends `Z` if missing to parse as UTC.

---

### 8.3 Get Patient's Next Appointment

| Property | Value |
|----------|-------|
| **Feature** | Get the next upcoming appointment for a patient |
| **Flutter file** | [`appointment_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/appointment_api_service.dart#L49) |
| **Screen / Flow** | [`patient_dashboard_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/patient/patient_dashboard_screen.dart) — appointment card |
| **User role** | Patient only |
| **HTTP method** | `GET` |
| **Endpoint** | `/appointments/patient/{patientId}/next` |
| **Auth required** | ✅ Yes |
| **Path params** | `patientId: int` |
| **Response shape** | `AppointmentModel` or `null` (204 No Content) |

---

### 8.4 Update Appointment Status

| Property | Value |
|----------|-------|
| **Feature** | Change appointment status (confirm, cancel, complete) |
| **Flutter file** | [`appointment_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/appointment_api_service.dart#L66) |
| **Screen / Flow** | [`doctor_appointments_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/doctor_appointments_screen.dart) |
| **User role** | Doctor (primary) |
| **HTTP method** | `PATCH` |
| **Endpoint** | `/appointments/{appointmentId}/status` |
| **Auth required** | ✅ Yes |
| **Path params** | `appointmentId: int` |
| **Request body** | `{ "status": "CONFIRMED" | "CANCELLED" | "COMPLETED" }` |
| **Response shape** | `AppointmentModel` |

---

## 9. NOTIFICATIONS — `/api/notifications/*`

### 9.1 Get Notifications (Paginated)

| Property | Value |
|----------|-------|
| **Feature** | List user's notifications with pagination |
| **Flutter file** | [`notification_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/notification_api_service.dart#L50) |
| **Screen / Flow** | Notifications screen |
| **User role** | Shared |
| **HTTP method** | `GET` |
| **Endpoint** | `/notifications/{userId}?page=0&size=20` |
| **Auth required** | ✅ Yes |
| **Path params** | `userId: int` |
| **Query params** | `page: int` (default 0), `size: int` (default 20) |
| **Response shape** | Paginated `{ content: List<NotificationItem> }` OR plain `List<NotificationItem>` |

**Response body (paginated — Spring Page):**
```json
{
  "content": [
    {
      "id": 1,
      "userId": 1,
      "type": "CHAT" | "APPOINTMENT_SCHEDULED" | "APPOINTMENT_CONFIRMED" | "PATIENT_ASSIGNED" | ...,
      "title": "New Message",
      "body": "You have a new message from Dr. Smith",
      "relatedId": 2,
      "relatedName": "Dr. Smith",
      "read": false,
      "createdAt": "2024-01-15T10:30:00"
    }
  ],
  "totalPages": 5,
  "totalElements": 100,
  "number": 0,
  "size": 20
}
```

**Notes for web:**
- The Flutter client handles BOTH paginated (`response.data['content']`) and flat list (`response.data as List`) formats.
- `isRead` field: the backend sends `"read"` (not `"isRead"`). The Flutter model checks both keys.

---

### 9.2 Get Unread Count

| Property | Value |
|----------|-------|
| **HTTP method** | `GET` |
| **Endpoint** | `/notifications/{userId}/unread-count` |
| **Response** | `{ "count": 5 }` |

### 9.3 Mark Single Notification Read

| Property | Value |
|----------|-------|
| **HTTP method** | `PUT` |
| **Endpoint** | `/notifications/{notificationId}/read/{userId}` |

### 9.4 Mark All Notifications Read

| Property | Value |
|----------|-------|
| **HTTP method** | `PUT` |
| **Endpoint** | `/notifications/{userId}/read-all` |

### 9.5 Mark Chat Notifications Read

| Property | Value |
|----------|-------|
| **HTTP method** | `PUT` |
| **Endpoint** | `/notifications/{userId}/read-chat/{senderId}` |

### 9.6 Mark Appointment Notifications Read

| Property | Value |
|----------|-------|
| **HTTP method** | `PUT` |
| **Endpoint** | `/notifications/{userId}/read-appointments` |

### 9.7 Delete Single Notification

| Property | Value |
|----------|-------|
| **HTTP method** | `DELETE` |
| **Endpoint** | `/notifications/{notificationId}/user/{userId}` |

### 9.8 Delete Chat Notifications from Sender

| Property | Value |
|----------|-------|
| **HTTP method** | `DELETE` |
| **Endpoint** | `/notifications/{userId}/chat/{senderId}` |

### 9.9 Delete All Notifications

| Property | Value |
|----------|-------|
| **HTTP method** | `DELETE` |
| **Endpoint** | `/notifications/{userId}/all` |

> **All notification endpoints**: Auth required ✅, Error handling: silently caught (non-critical).

---

## 10. AI ASSESSMENT — `/api/ai/*`

### 10.1 Submit Assessment

| Property | Value |
|----------|-------|
| **Feature** | Submit cardiac assessment questionnaire for AI analysis |
| **Flutter file** | [`ai_assessment_api.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/data/ai_assessment_api.dart#L14) |
| **Screen / Flow** | [`assessment_flow_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/assessment_flow_screen.dart) → [`review_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/review_screen.dart) |
| **User role** | Patient only |
| **HTTP method** | `POST` |
| **Endpoint** | `/ai/consult/{patientId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `patientId: int` |
| **Request body** | `Map<String, dynamic>` — full assessment questionnaire JSON |
| **Response shape** | `AiConsultResponse` |
| **Timeouts** | Send: 30s, Receive: **6 minutes** (AI processing is slow) |

**Response body:**
```json
{
  "id": 1,
  "patientId": 1,
  "patientInput": "stringified JSON of input",
  "patientRequestData": "string" | null,
  "patientName": "John",
  "patientAge": 25,
  "patientGender": "MALE",
  "patientHeight": 170.0,
  "patientWeight": 70.0,
  "aiReport": "Markdown-formatted AI analysis report",
  "createdAt": "2024-01-15T10:30:00"
}
```

**Notes for web:**
- Very long receive timeout (6 min) — use a loading overlay with cancel option.
- The `aiReport` field contains a full markdown-formatted report.

---

### 10.2 Get My Reports (Patient)

| Property | Value |
|----------|-------|
| **Feature** | Fetch the authenticated patient's past AI reports |
| **Flutter file** | [`ai_assessment_api.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/data/ai_assessment_api.dart#L69) |
| **Screen / Flow** | [`report_history_screen.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/screens/report_history_screen.dart) |
| **User role** | Patient only |
| **HTTP method** | `GET` |
| **Endpoint** | `/ai/my-reports` |
| **Auth required** | ✅ Yes |
| **Response shape** | `List<AiConsultResponse>` |

---

### 10.3 Get Patient Reports (Doctor View)

| Property | Value |
|----------|-------|
| **Feature** | Fetch a specific patient's AI reports (for doctor review) |
| **Flutter file** | [`ai_assessment_api.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/data/ai_assessment_api.dart#L98) |
| **Screen / Flow** | [`patient_detail_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/doctor/patient_detail_screen.dart) |
| **User role** | Doctor only |
| **HTTP method** | `GET` |
| **Endpoint** | `/ai/history/{patientId}` |
| **Auth required** | ✅ Yes |
| **Path params** | `patientId: int` |
| **Response shape** | `List<AiConsultResponse>` |

---

## 11. SERVER HEALTH CHECK

### 11.1 Test Connection

| Property | Value |
|----------|-------|
| **Feature** | Verify backend server is reachable |
| **Flutter file** | [`api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/api_service.dart) |
| **Screen / Flow** | [`splash_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/splash/splash_screen.dart) — network gate |
| **HTTP method** | `GET` |
| **Endpoint** | Base URL root (`/api`) |
| **Auth required** | ❌ No |
| **Timeout** | 4 seconds |
| **Response** | Any HTTP response = server is up (even 401/403/404/500) |

**Notes for web:**
- Used as a connectivity check. Any HTTP response (regardless of status code) means the server is physically up.
- On web, can be replaced with a simple `fetch()` with `no-cors` or a dedicated health endpoint.

---

## Complete Endpoint Summary Table

| # | Method | Endpoint | Auth | Role | Service File |
|---|--------|----------|------|------|-------------|
| 1 | POST | `/auth/register` | ❌ | Shared | `backend_auth_service.dart` |
| 2 | POST | `/auth/login` | ❌ | Shared | `backend_auth_service.dart` |
| 3 | GET | `/user/me` | ✅ | Shared | `backend_auth_service.dart` |
| 4 | PUT | `/user/me` | ✅ | Shared | `user_api_service.dart` |
| 5 | PUT | `/user/fcm-token` | ✅ | Shared | `push_notification_service.dart` |
| 6 | POST | `/doctor/assign` | ✅ | Doctor | `doctor_api_service.dart` |
| 7 | GET | `/doctor/patients/{doctorId}` | ✅ | Doctor | `doctor_api_service.dart` |
| 8 | GET | `/doctor/search/name` | ✅ | Doctor | `doctor_api_service.dart` |
| 9 | GET | `/doctor/search/phone` | ✅ | Doctor | `doctor_api_service.dart` |
| 10 | DELETE | `/doctor/remove` | ✅ | Doctor | `doctor_api_service.dart` |
| 11 | GET | `/patient/doctor/{patientId}` | ✅ | Patient | `patient_api_service.dart` |
| 12 | POST | `/iot/upload/{patientId}` | ✅ | Patient | `iot_api_service.dart` |
| 13 | GET | `/iot/latest/{patientId}` | ✅ | Shared | `iot_api_service.dart` |
| 14 | GET | `/iot/history/{patientId}` | ✅ | Shared | `iot_api_service.dart` |
| 15 | GET | `/iot/summary/{patientId}` | ✅ | Shared | `iot_api_service.dart` |
| 16 | GET | `/iot/summary/hourly/{patientId}` | ✅ | Shared | `iot_api_service.dart` |
| 17 | GET | `/chat/history/{userId1}/{userId2}` | ✅ | Shared | `chat_service.dart` |
| 18 | GET | `/chat/conversations/{userId}` | ✅ | Shared | `chat_service.dart` |
| 19 | PUT | `/chat/read/{senderId}/{receiverId}` | ✅ | Shared | `chat_service.dart` |
| 20 | PUT | `/chat/deliver/{senderId}/{receiverId}` | ✅ | Shared | `chat_service.dart` |
| 21 | GET | `/presence/{userId}` | ✅ | Shared | `presence_service.dart` |
| 22 | PUT | `/presence/heartbeat/{userId}` | ✅ | Shared | `presence_service.dart` |
| 23 | POST | `/appointments/schedule` | ✅ | Doctor | `appointment_api_service.dart` |
| 24 | GET | `/appointments/doctor/{doctorId}` | ✅ | Doctor | `appointment_api_service.dart` |
| 25 | GET | `/appointments/patient/{patientId}/next` | ✅ | Patient | `appointment_api_service.dart` |
| 26 | PATCH | `/appointments/{appointmentId}/status` | ✅ | Doctor | `appointment_api_service.dart` |
| 27 | GET | `/notifications/{userId}` | ✅ | Shared | `notification_api_service.dart` |
| 28 | GET | `/notifications/{userId}/unread-count` | ✅ | Shared | `notification_api_service.dart` |
| 29 | PUT | `/notifications/{notificationId}/read/{userId}` | ✅ | Shared | `notification_api_service.dart` |
| 30 | PUT | `/notifications/{userId}/read-all` | ✅ | Shared | `notification_api_service.dart` |
| 31 | PUT | `/notifications/{userId}/read-chat/{senderId}` | ✅ | Shared | `notification_api_service.dart` |
| 32 | PUT | `/notifications/{userId}/read-appointments` | ✅ | Shared | `notification_api_service.dart` |
| 33 | DELETE | `/notifications/{notificationId}/user/{userId}` | ✅ | Shared | `notification_api_service.dart` |
| 34 | DELETE | `/notifications/{userId}/chat/{senderId}` | ✅ | Shared | `notification_api_service.dart` |
| 35 | DELETE | `/notifications/{userId}/all` | ✅ | Shared | `notification_api_service.dart` |
| 36 | POST | `/ai/consult/{patientId}` | ✅ | Patient | `ai_assessment_api.dart` |
| 37 | GET | `/ai/my-reports` | ✅ | Patient | `ai_assessment_api.dart` |
| 38 | GET | `/ai/history/{patientId}` | ✅ | Doctor | `ai_assessment_api.dart` |
