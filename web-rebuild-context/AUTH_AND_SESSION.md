# AUTH_AND_SESSION.md — Authentication & Session Management

> **Source of truth:** Extracted from the Flutter codebase's auth services, token management, and session handling.

---

## Architecture Overview

The Flutter app uses a **hybrid authentication** system:

1. **Firebase Auth** — Identity provider (email/password + Google Sign-In)
2. **Backend JWT** — API access token from the Spring Boot backend

For the **web rebuild**, Firebase Auth can be eliminated entirely. The backend's own auth endpoints (`/api/auth/login`, `/api/auth/register`) are the source of truth. Firebase Auth is only used in the mobile app for identity verification and Google Sign-In OAuth flow.

```
┌──────────────────────────────────────────────────────────────┐
│                    FLUTTER AUTH FLOW                          │
│                                                              │
│  Firebase Auth (identity) ──→ Backend /auth/login (JWT)      │
│                                                              │
│                    WEB AUTH FLOW (simplified)                 │
│                                                              │
│  Backend /auth/register ──→ Backend /auth/login (JWT)        │
│  Store JWT in localStorage/cookie                            │
└──────────────────────────────────────────────────────────────┘
```

---

## Login Endpoint

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /api/auth/login` |
| **Auth required** | ❌ No |
| **Source file** | [`backend_auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/backend_auth_service.dart#L38) |

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "token": "REMOVED"
}
```

**Error responses:**
- `401 Unauthorized` — Invalid credentials → `UnauthorizedException`
- `400 Bad Request` — Missing fields → `ValidationException`

### Flutter Login Flow ([`auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart#L150))

1. Firebase `signInWithEmailAndPassword` (skip this on web)
2. `POST /api/auth/login` → get JWT
3. Save JWT to secure storage (`TokenService.saveToken`)
4. Save email + password to secure storage (`TokenService.saveCredentials`) — used for auto-refresh
5. Load user data from local storage → if missing, fetch from Firestore → if still missing, create minimal model
6. If `backendId` is null, call `GET /user/me` to populate it
7. Save user to local storage

### Web Login Flow (Recommended)

1. `POST /api/auth/login` → get JWT
2. Store JWT in `localStorage` (or `httpOnly` cookie for better security)
3. Store email + password in `sessionStorage` (for auto-refresh on 401)
4. `GET /api/user/me` → get full user profile including `id` (backendId), `role`, etc.
5. Store user profile in state management (React context, Zustand, etc.)
6. Redirect based on role: `/doctor/dashboard` or `/patient/dashboard`

---

## Register Endpoint

| Property | Value |
|----------|-------|
| **Endpoint** | `POST /api/auth/register` |
| **Auth required** | ❌ No |
| **Source file** | [`backend_auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/backend_auth_service.dart#L18) |

**Request:**
```json
{
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "securepass123",
  "phoneNumber": "+1234567890",
  "role": "PATIENT",
  "dateOfBirth": "1990-05-15",
  "gender": "MALE",
  "height": 175.0,
  "weight": 70.0
}
```

**Response (200/201):**
```json
{
  "id": 1,
  "fullName": "John Doe",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "PATIENT",
  "phoneNumber": "+1234567890",
  "dateOfBirth": "1990-05-15",
  "gender": "MALE",
  "height": 175.0,
  "weight": 70.0,
  "profileImageUrl": null
}
```

**Error responses:**
- `409 Conflict` — Email already exists → `ConflictException`

### Flutter Registration Flow ([`auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart#L48))

1. `POST /api/auth/register` → create backend user (source of truth)
2. Firebase `createUserWithEmailAndPassword` (skip on web)
3. `POST /api/auth/login` → get JWT
4. Save JWT + credentials
5. Build `UserModel` from backend response
6. Save to Firestore (skip on web)
7. Save to local Hive storage (skip on web — use state management)

### Web Registration Flow (Recommended)

1. `POST /api/auth/register` → create user
2. `POST /api/auth/login` → get JWT
3. Store JWT + credentials
4. `GET /api/user/me` → get full profile
5. Redirect based on role

### Important Registration Notes

- **Role selection**: The Flutter app converts title-case "Doctor"/"Patient" to uppercase "DOCTOR"/"PATIENT" before sending.
- **dateOfBirth format**: `YYYY-MM-DD` (date only, no time component).
- **gender values**: `"MALE"` or `"FEMALE"` (uppercase).
- **height/weight**: Only sent for patients. Omitted (not included in JSON) for doctors.
- **Response field difference**: The register response uses `"name"` while the `/user/me` response uses `"fullName"`. The Flutter `UserModel.fromBackendJson` handles both: `json['fullName'] ?? json['name']`.

---

## Logout Behavior

**Source:** [`auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart#L21)

### Flutter Logout Steps

1. `FirebaseAuth.instance.signOut()` (skip on web)
2. `GoogleSignIn().signOut()` (skip on web)
3. `TokenService.clearAll()` — deletes JWT, email, password from secure storage
4. (Implicit) `StorageService.logout()` — clears local Hive user box

### Web Logout Steps (Recommended)

1. Clear JWT from `localStorage`/cookie
2. Clear stored credentials from `sessionStorage`
3. Clear user state from state management
4. Disconnect WebSocket (STOMP deactivate)
5. Stop presence heartbeat
6. Redirect to login page

### Force Logout (Token Expired)

**Source:** [`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L172)

Triggered when auto-refresh fails on a 401/403:

1. Delete JWT token (keep credentials for potential re-login)
2. Clear local user storage (`StorageService.logout()`)
3. Shut down WebSocket (`ChatService.shutdown()`)
4. Sign out Firebase
5. Show error toast: "Session Expired — Your session has expired. Please log in again."
6. Navigate to `/auth` route, removing all previous routes

**Force-logout guard:** A static `_hasForceLoggedOut` boolean prevents multiple concurrent 401 errors from triggering multiple logouts. Reset after successful login via `DioClient.resetForceLogoutGuard()`.

---

## Token Storage

### Flutter Implementation ([`token_service.dart`](file:///e:/side%20projects/gp_app/lib/services/token_service.dart))

| Key | Storage | Purpose |
|-----|---------|---------|
| `backend_jwt_token` | `FlutterSecureStorage` | JWT for API authentication |
| `backend_email` | `FlutterSecureStorage` | Stored email for auto-refresh |
| `backend_password` | `FlutterSecureStorage` | Stored password for auto-refresh |

### Web Recommendation

| Data | Storage | Why |
|------|---------|-----|
| JWT | `localStorage` or `httpOnly` cookie | Persists across page refreshes |
| Email + password | `sessionStorage` | For auto-refresh; cleared on tab close |
| User profile | In-memory state (React context/Zustand) | Fast access, re-fetched on reload |

---

## Refresh Token Behavior

**There is NO dedicated refresh token endpoint.** The backend only issues access tokens via `/auth/login`.

### How the Flutter App Handles Token Expiry

**Source:** [`dio_client.dart`](file:///e:/side%20projects/gp_app/lib/core/api/dio_client.dart#L96) (Dio interceptor), [`auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart#L320)

1. Any API call returns `401` or `403` (non-auth endpoint)
2. Dio interceptor catches it
3. Reads stored credentials from `TokenService.getCredentials()`
4. Calls `POST /api/auth/login` to get a fresh JWT
5. Saves the new JWT via `TokenService.saveToken()`
6. **Retries the original failed request** with the new token
7. If re-login also fails → force logout

### Flow Diagram

```
API call → 401 Unauthorized
  ├─ Is it an auth endpoint (/auth/login, /auth/register)?
  │   └─ YES → Don't retry. Pass error through.
  ├─ Already refreshing?
  │   └─ YES → Don't retry. Pass error through.
  ├─ Already force-logged-out?
  │   └─ YES → Don't retry. Pass error through.
  └─ NO to all above →
      ├─ Read stored credentials (email/password)
      │   └─ null → Force logout
      ├─ POST /api/auth/login
      │   ├─ Success → Save new JWT, retry original request
      │   └─ Failure →
      │       ├─ 401/403 → Force logout
      │       └─ Other error → Pass error through
      └─ Return retry response or error
```

### Web Implementation Notes

- Implement the same interceptor pattern in your HTTP client (Axios interceptor, fetch wrapper, etc.)
- On 401 for non-auth endpoints:
  1. Read stored credentials
  2. Call `POST /api/auth/login`
  3. Update stored JWT
  4. Retry original request
- Use a mutex/flag to prevent concurrent refresh attempts

### Background Service Token Refresh

The [`health_monitor_service.dart`](file:///e:/side%20projects/gp_app/lib/services/health_monitor_service.dart#L671) background service has its own independent token refresh:

1. Upload fails with 401/403
2. Reads credentials from `FlutterSecureStorage` directly (separate isolate)
3. Calls `POST /auth/login` with a fresh Dio instance (no interceptors)
4. Saves new token to `FlutterSecureStorage`
5. Updates the Dio instance's `Authorization` header

This is mobile-only and irrelevant for web.

---

## Current User / Profile Fetching

**Endpoint:** `GET /api/user/me`  
**Source:** [`backend_auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/backend_auth_service.dart#L59)

Called in these scenarios:
1. **After login** — to populate `backendId` if missing ([`auth_service.dart` L200](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart#L200))
2. **After Google Sign-In** — for returning users ([`auth_service.dart` L271](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart#L271))
3. **Splash screen** — indirectly through `refreshBackendToken` flow

**Response fields used:**

| Field | Type | Usage |
|-------|------|-------|
| `id` | `int` | Backend ID — required for ALL API calls that take userId/patientId/doctorId |
| `role` | `string` | `"DOCTOR"` or `"PATIENT"` — determines dashboard routing |
| `fullName` | `string` | Display name |
| `email` | `string` | User email |
| `phoneNumber` | `string?` | Phone number |
| `dateOfBirth` | `string?` | ISO date string |
| `gender` | `string?` | `"MALE"` or `"FEMALE"` |
| `height` | `number?` | Height in cm |
| `weight` | `number?` | Weight in kg |
| `profileImageUrl` | `string?` | Base64 data URI or URL |

---

## Role Detection

**Source:** [`user_model.dart`](file:///e:/side%20projects/gp_app/lib/models/user_model.dart), [`auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart)

### Backend Role Values
- `"DOCTOR"` (uppercase)
- `"PATIENT"` (uppercase)

### Flutter Display Values
- `"Doctor"` (title-case)
- `"Patient"` (title-case)

### Role Conversion
```dart
// Backend → Display
final role = backendRole == 'DOCTOR' ? 'Doctor' : 'Patient';

// Display → Backend
String get backendRole => role == 'Doctor' ? 'DOCTOR' : 'PATIENT';
```

### Where Role is Used

| Usage | Doctor | Patient |
|-------|--------|---------|
| Dashboard route | `/doctor_dashboard` | `/patient_dashboard` |
| Patient list | ✅ (API: `/doctor/patients/{id}`) | ❌ |
| Health monitoring | Views patient data | Views own data / IoT upload |
| Chat | Chats with patients | Chats with assigned doctor |
| Appointments | Schedules & manages | Views next appointment |
| AI Assessment | Views patient reports | Submits & views own reports |
| Patient search | ✅ (search/assign) | ❌ |

---

## Protected Route Behavior

### Flutter Route Protection ([`splash_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/splash/splash_screen.dart))

```
App Start
  ├─ Firebase user exists?
  │   ├─ NO → Onboarding screen
  │   └─ YES →
  │       ├─ Backend credentials exist?
  │       │   └─ NO → Sign out + Onboarding (zombie state)
  │       ├─ Internet available?
  │       │   └─ NO → "No Internet" screen (blocks)
  │       ├─ Server reachable?
  │       │   └─ NO → "Server Down" screen (blocks with retry)
  │       ├─ Refresh JWT (proactive)
  │       ├─ Local user profile exists?
  │       │   ├─ YES, role=Doctor → /doctor_dashboard
  │       │   ├─ YES, role=Patient →
  │       │   │   ├─ Profile complete? → /patient_dashboard
  │       │   │   └─ Profile incomplete? → /assessment_welcome
  │       │   └─ NO → /role_selection
  │       └─ (fallback) → /role_selection
```

### Web Route Protection (Recommended)

```typescript
// Middleware / route guard
function authGuard(to, from, next) {
  const jwt = localStorage.getItem('jwt');
  const user = getUserFromState();

  if (!jwt) return redirect('/login');
  
  if (!user) {
    // Fetch user profile
    const profile = await fetchUserProfile();
    setUser(profile);
  }

  if (to.meta.requiresDoctor && user.role !== 'DOCTOR') {
    return redirect('/patient/dashboard');
  }
  if (to.meta.requiresPatient && user.role !== 'PATIENT') {
    return redirect('/doctor/dashboard');
  }

  next();
}
```

---

## What Happens if Token Expires

1. **First API call fails with 401** → Dio interceptor catches it
2. **Auto-refresh attempt** using stored credentials → `POST /api/auth/login`
3. **If refresh succeeds** → Retry original request transparently (user doesn't notice)
4. **If refresh fails** → Force logout:
   - Delete JWT
   - Clear user data
   - Shut down WebSocket
   - Show "Session Expired" toast
   - Redirect to login page

---

## What Happens if Unauthorized (403 Forbidden)

Same flow as 401 — the interceptor treats both identically:

1. Attempt auto-refresh
2. If refresh succeeds → retry
3. If refresh fails with 401/403 → force logout
4. If refresh fails with other error → pass error through

---

## Doctor vs Patient Login Differences

### During Login
- **No difference in the login API call itself** — same endpoint, same payload
- The role is stored on the backend; the client discovers it after login

### After Login
- **Doctor**: `GET /api/user/me` returns `role: "DOCTOR"` → route to `/doctor_dashboard`
- **Patient**: `GET /api/user/me` returns `role: "PATIENT"` → route to `/patient_dashboard`

### Google Sign-In Differences ([`auth_service.dart`](file:///e:/side%20projects/gp_app/lib/services/auth_service.dart#L239))
- **New Google user**: No backend account → directed to role selection screen → user picks Doctor or Patient → `POST /api/auth/register` with chosen role → then login
- **Returning Google user**: Backend account exists → `POST /api/auth/login` succeeds → fetch profile → route by role
- **Google password**: A deterministic password `"GoogleAuth_{firebaseUid}"` is generated. On web, this needs to be handled differently since there's no Firebase UID.

---

## Onboarding / Profile-Completion Logic

### Role Selection ([`role_selection_screen.dart`](file:///e:/side%20projects/gp_app/lib/screens/role_selection/role_selection_screen.dart))

**When shown:** After Google Sign-In for new users who don't have a backend account.

**Flow:**
1. User picks "Doctor" or "Patient"
2. `POST /api/auth/register` with the chosen role
3. `POST /api/auth/login` → get JWT
4. `GET /api/user/me` → get backendId
5. Route to appropriate dashboard

### Profile Completion Guard ([`splash_screen.dart` L252](file:///e:/side%20projects/gp_app/lib/screens/splash/splash_screen.dart#L252))

**Patient only.** On app launch, if the patient's profile is missing essential fields:

```dart
final profileIncomplete = user.dateOfBirth == null ||
    user.gender == null ||
    user.height == null ||
    user.weight == null;
```

If incomplete → redirect to `/assessment_welcome` (AI assessment welcome screen) instead of dashboard.

**Notes for web:**
- Implement a similar guard: after login, check if essential profile fields are populated
- If not, redirect to a profile completion / assessment page
- The TODO in the Flutter code mentions replacing this with a dedicated backend flag (`user.hasCompletedInitialAssessment`)

---

## Session Persistence Summary

| What | Flutter Storage | Web Equivalent |
|------|----------------|----------------|
| JWT Token | `FlutterSecureStorage` | `localStorage` / `httpOnly` cookie |
| Credentials (email/pass) | `FlutterSecureStorage` | `sessionStorage` |
| User Profile | Hive local DB | In-memory state + re-fetch from `/user/me` |
| Settings (dark mode, language, notifications) | Hive local DB | `localStorage` |
| Measurements (local cache) | Hive local DB | Not needed for web |

---

## Complete Auth-Related API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `POST /api/auth/register` | POST | Create new user |
| `POST /api/auth/login` | POST | Get JWT token |
| `GET /api/user/me` | GET | Get current user profile |
| `PUT /api/user/me` | PUT | Update profile |
| `PUT /api/user/fcm-token` | PUT | Register push notification token |
