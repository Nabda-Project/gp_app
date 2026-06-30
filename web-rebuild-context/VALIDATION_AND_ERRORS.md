# VALIDATION_AND_ERRORS.md — Form Validation, Error Handling, UX Messages

> Captures the exact validation rules, error classes, and user-visible
> error/empty/loading messages from the Flutter app. The web app should
> reuse the same strings (in EN and AR) so the doctor experience is
> identical.

---

## 1. Form validation rules

### 1.1 Login form (`auth_screen.dart`)
- **Email:**
  - Required → "Please enter your email" / "أدخل بريدك الإلكتروني".
  - Must match RFC-style regex (basic): "Please enter a valid email" /
    "أدخل بريدًا إلكترونيًا صالحًا".
- **Password:**
  - Required → "Please enter your password" / "أدخل كلمة المرور".
  - Length ≥ 6 → "Password must be at least 6 characters" /
    "يجب أن تتكون كلمة المرور من 6 أحرف على الأقل".

Source: `lib/utils/app_localizations.dart` (`enterEmail`, `validEmail`,
`enterPassword`, `passwordLength`).

### 1.2 Register form
- All of the above (with stricter password length 8 for register: key
  `passwordLength8` "Password must be at least 8 characters").
- **Full name:** "Please enter your full name".
- **Phone number:** "Please enter your phone number".
- **Confirm password:** matches password ("Passwords do not match"
  / `passwordsNoMatch`).
- **Date of birth (required):** "Please select your Date of Birth".
- **Gender (required):** "Please select your Gender".
- **Patient-only:**
  - **Height (required, numeric):** "Please enter your height" /
    `enterHeight`. Reject non-numeric: "Please enter valid numbers
    for height and weight".
  - **Weight (required, numeric):** "Please enter your weight" /
    `enterWeight`.

Source: `lib/screens/auth/auth_screen.dart:115-198`,
`lib/screens/role_selection/role_selection_screen.dart:48-100`.

For the **doctor** web app, height/weight are not required.

### 1.3 Appointment scheduling
- **Date:** must be ≥ today (date picker bounds).
- **Time:** result of combining picked date+time must be > now,
  else toast: "Cannot schedule appointments in the past."
- **Reason:** optional, trimmed; empty ⇒ omit from request body.

Source: `lib/screens/doctor/patient_detail_screen.dart:553-660`.

### 1.4 Assign patient search
- Minimum query length: 2 characters before triggering search.
  Source: `lib/widgets/reusable/assign_patient_sheet.dart:70`.
- Debounce: 500 ms before firing.

---

## 2. API error classes & default messages

Source: `lib/core/api/api_exceptions.dart`, `lib/core/api/dio_client.dart:195-241`.

| Class                     | HTTP        | Default message                                          | Localization key    |
|---------------------------|-------------|----------------------------------------------------------|---------------------|
| `ApiException` (base)     | any         | "Unexpected error (HTTP {code})."                         | `unexpectedError`   |
| `ValidationException`     | 400         | "Invalid request."                                       | n/a                 |
| `UnauthorizedException`   | 401         | "Session expired. Please log in again."                  | `sessionExpiredTitle`/`sessionExpired` (mobile uses raw strings) |
| `ForbiddenException`      | 403         | "You do not have permission for this action."            | n/a                 |
| `ConflictException`       | 409         | "Resource already exists."                               | n/a                 |
| `ServerException`         | 500         | "An unexpected server error occurred."                   | `serverError`       |
| `NetworkException`        | timeout / connect | "Network error. Please check your connection."     | `connectionError`   |

Server response body (when present) takes precedence:
```
{ "message": "…" }   → use message
{ "error": "…" }     → use error
"<string>"           → use as message
```

Source: `lib/core/api/dio_client.dart:208-215`.

---

## 3. Localized error labels (extracted from `app_localizations.dart`)

| Key                  | EN                                                    | AR (verify in code)        |
|----------------------|-------------------------------------------------------|----------------------------|
| `serverError`        | "Server error. Please try again later."               | "خطأ في الخادم..."          |
| `connectionError`    | "Cannot reach server. Please check your connection."  | "تعذر الوصول للخادم..."     |
| `unexpectedError`    | "Unexpected error. Please try again."                 | "حدث خطأ غير متوقع..."      |
| `serverDownTitle`    | "Server is Down"                                      | "الخادم متوقف"              |
| `serverDownDesc`     | "We're having trouble connecting to our server. We'll reconnect automatically." | (verify) |
| `noInternetTitle`    | "No Internet Connection"                              | "لا يوجد اتصال بالإنترنت"   |
| `noInternetDesc`     | "Please check your network and try again."            | (verify)                   |
| `reconnecting`       | "Reconnecting..."                                     | (verify)                   |
| `retry`              | "Retry"                                               | "إعادة المحاولة"            |
| `cancel`             | "Cancel"                                              | "إلغاء"                     |
| `remove`             | "Remove"                                              | "إزالة"                     |

For the full string set, the web app should copy from
`lib/utils/app_localizations.dart` (the master EN/AR map).

---

## 4. Session expiry handling

When the JWT cannot be refreshed (401/403 → re-login fails):
- Force logout the user via `_forceLogoutAndRedirect`.
- Show **error** toast:
  - Title: `"Session Expired"`.
  - Message: `"Your session has expired. Please log in again."`.
- Navigate to `/auth` and remove all routes from the stack.
- A static guard prevents this from firing more than once across
  concurrent 401s.

Source: `lib/core/api/dio_client.dart:172-193`.

The web app should:
- Show a top toast.
- Clear all auth state.
- Redirect to `/login`.
- Use a global "ALREADY_LOGGED_OUT" guard to prevent duplicate redirects.

---

## 5. Snackbar / toast types

(Source: `lib/widgets/reusable/animated_toast.dart`,
`lib/services/notification_service.dart`.)

| Type     | API call                              | Color    | Typical use                          |
|----------|---------------------------------------|----------|--------------------------------------|
| success  | `NotificationService.showSuccess`     | `#00E676`| "Account created successfully!", "Patient assigned" |
| error    | `NotificationService.showError`       | `#FF5252`| Auth + API errors                    |
| warning  | `NotificationService.showWarning`     | `#FFAB40`| Validation hints                     |
| info     | `NotificationService.showInfo`        | `#448AFF`| Heads-up incoming messages           |

Auto-dismiss: 4 s. Swipe-up to dismiss (mobile). Position: top.

Heads-up notifications respect the user setting:
`settings.enableNotifications`. When disabled, both in-app heads-up and
Android system notifications are suppressed.

Source: `notification_service.dart:33-46`,
`push_notification_service.dart:230-258`.

---

## 6. Empty / loading / error states by screen

### 6.1 Dashboard "Recent Patients"
- Loading: centered `CircularProgressIndicator`.
- Error: error icon + message + "Retry".
- Empty: `Icons.people_outline` + "No patients assigned yet."

### 6.2 Patients tab
- Loading: `ListSkeleton(itemCount: 6, hasAvatar: true)`.
- Error: `EmptyStateView(icon: error_outline_rounded, title: 'Failed to load patients', description: <error>, actionText: 'Retry')`.
- Empty no search: `EmptyStateView(icon: group_off_rounded, title: 'No patients assigned yet.', description: 'Assign a new patient to start monitoring them.')`.
- Empty with search: `EmptyStateView(icon: search_off_rounded, title: 'No patients found', description: 'Try modifying your search query.', actionText: 'Clear Search')`.

### 6.3 Chats tab
- Loading: `ListSkeleton(itemCount: 8, hasAvatar: true)`.
- Empty: `EmptyStateView(icon: chat_bubble_outline_rounded, title: 'No conversations yet', description: 'Start chatting from the Patients tab!', actionText: 'Refresh')`.

### 6.4 Appointments
- Loading: `ListSkeleton(itemCount: 4, hasAvatar: false)`.
- Error: `EmptyStateView(icon: error_outline_rounded, title: 'Error loading', description: <error>)`.

### 6.5 AssignPatientSheet (search)
- Initial (no query / < 2 chars): "Type at least 2 characters to search" pattern (`typeToSearch` key) with a faded search icon.
- Searching: spinner + `searching` label.
- Empty results: `Icons.search_off_rounded` + `noResults`.
- Error: red banner with `error_outline`, the error text, and a "Retry" button.

### 6.6 Vitals
- Loading: full-screen `CircularProgressIndicator`.
- Load error: `_loadError = true` shows the "Connection / load failed" banner.
- Live updates: a connection-state banner ("Reconnecting…" or "Offline")
  when STOMP is not connected.

### 6.7 Splash
- NoInternet: `NoInternetView`.
- Server down: `ServerDownView(onRefresh: …)`.

---

## 7. Doctor-side authorization error UX

If the backend returns 403 to a doctor endpoint, mobile maps it to
`ForbiddenException("You do not have permission for this action.")`.

For the web app:
- If `/user/me` returns role `PATIENT` after login → sign out + toast:
  "Doctor account required" (custom string; mobile doesn't have this
  flow because patients use the same app).

---

## 8. Field-level error display

Mobile uses `Form` + `TextFormField.validator` which renders the error
inline below each field. The web app should:
- Use a `<label>` + `<input>` + `<div role="alert">` pattern.
- Show the same validation strings (translate via the localization map).
- Trim user input before validation.

---

## 9. Numeric input formatting (height / weight)

- Trim whitespace before parsing.
- Use `double.tryParse` semantics (allow `.` decimal). The web app
  should reject `,` decimals unless explicitly localized.
- Reject if `<= 0` or `> reasonable max` (mobile doesn't enforce; you may
  add `height ∈ [50, 250] cm` and `weight ∈ [10, 400] kg`).

Source: `auth_screen.dart:140-167`.

---

## 10. Phone number validation

Mobile does not regex-validate phone numbers; it only requires non-empty.
The web app could match Egyptian formats (`+20`/`01[0-2,5]\d{8}`) but
must mirror mobile's leniency by default.

Source: `role_selection_screen.dart:76-84`.

---

## 11. Notification permission UX

Web has no equivalent permission flow yet (web push is out of scope for
v1). Skip the "Allow notifications" dialog. The `Settings` toggle should
control in-app toasts only.

---

## 12. Error analytics / logging

Mobile uses `dart:developer log()` with named loggers
(`DoctorDashboard`, `AssignPatient`, `ChatService`, etc.). The web app
should:
- Log to the browser console with module-scoped prefixes.
- Optionally wire Sentry or similar; not required for parity.
