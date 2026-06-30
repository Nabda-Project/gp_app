# DATA_MODELS.md — Complete Data Model Reference

> **Source of truth:** Every model used in API communication, extracted from the Flutter `lib/models/` directory and inline model definitions in service files.
> Each model includes field types, nullability, enum values, and which API responses it appears in.

---

## 1. UserModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`user_model.dart`](file:///e:/side%20projects/gp_app/lib/models/user_model.dart) |
| **Local storage** | Hive (typeId: 0) |
| **Doctor usage** | Represents the logged-in doctor |
| **Patient usage** | Represents the logged-in patient |
| **API responses** | `GET /user/me`, `POST /auth/register` (response), Google Sign-In profile fetch |

### Fields

| Field | Type | Nullable | Description | Notes |
|-------|------|----------|-------------|-------|
| `id` | `string` | ❌ | Firebase UID | **Web: not needed** — Firebase-specific |
| `backendId` | `int` | ✅ | PostgreSQL auto-increment ID | **This is the ID used in ALL API calls** (doctorId, patientId, userId) |
| `fullName` | `string` | ❌ | Full display name | Backend register response uses `"name"` key; `/user/me` uses `"fullName"` |
| `email` | `string` | ❌ | Email address | |
| `role` | `string` | ❌ | `"Patient"` or `"Doctor"` | Title-case for display. Backend uses uppercase: `"PATIENT"` / `"DOCTOR"` |
| `phoneNumber` | `string` | ✅ | Phone number | |
| `licenseNumber` | `string` | ✅ | Doctor's medical license | Not used in any API call currently |
| `dateOfBirth` | `DateTime` | ✅ | Date of birth | Backend format: `"YYYY-MM-DD"` ISO string |
| `gender` | `string` | ✅ | `"MALE"` or `"FEMALE"` | Uppercase from backend |
| `height` | `double` | ✅ | Height in centimeters | Patients only |
| `weight` | `double` | ✅ | Weight in kilograms | Patients only |
| `profileImageUrl` | `string` | ✅ | Profile image | Stored as Base64 data URI: `"data:image/jpeg;base64,..."` or empty string |

### Factory Methods

**`fromBackendJson(Map json, {String? firebaseUid})`** — Handles both registration response and `/user/me` response:
- Reads `fullName` from `json['fullName'] ?? json['name']`
- Converts role: `'DOCTOR'` → `'Doctor'`, `'PATIENT'` → `'Patient'`
- Parses `dateOfBirth` with `DateTime.tryParse`

**`fromMap(Map json)`** — From Firestore document (includes all fields)

### Computed Properties

| Property | Type | Value |
|----------|------|-------|
| `backendRole` | `string` | `role == 'Doctor' ? 'DOCTOR' : 'PATIENT'` |

### TypeScript Interface

```typescript
interface User {
  id: number;              // backendId — the only ID needed for web
  fullName: string;
  email: string;
  role: 'DOCTOR' | 'PATIENT';
  phoneNumber?: string | null;
  dateOfBirth?: string | null;  // "YYYY-MM-DD"
  gender?: 'MALE' | 'FEMALE' | null;
  height?: number | null;  // cm
  weight?: number | null;  // kg
  profileImageUrl?: string | null;  // Base64 data URI or empty string
}
```

---

## 2. AuthResponse

| Property | Value |
|----------|-------|
| **Flutter file** | [`auth_response.dart`](file:///e:/side%20projects/gp_app/lib/models/auth_response.dart) |
| **API responses** | `POST /auth/login` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `token` | `string` | ❌ | JWT access token |

### TypeScript Interface

```typescript
interface AuthResponse {
  token: string;
}
```

---

## 3. LoginRequest

| Property | Value |
|----------|-------|
| **Flutter file** | [`login_request.dart`](file:///e:/side%20projects/gp_app/lib/models/login_request.dart) |
| **API requests** | `POST /auth/login` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `email` | `string` | ❌ | User email |
| `password` | `string` | ❌ | User password |

### TypeScript Interface

```typescript
interface LoginRequest {
  email: string;
  password: string;
}
```

---

## 4. RegisterRequest

| Property | Value |
|----------|-------|
| **Flutter file** | [`register_request.dart`](file:///e:/side%20projects/gp_app/lib/models/register_request.dart) |
| **API requests** | `POST /auth/register` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `fullName` | `string` | ❌ | Full name |
| `email` | `string` | ❌ | Email |
| `password` | `string` | ❌ | Password |
| `phoneNumber` | `string` | ❌ | Phone number |
| `role` | `string` | ❌ | `"PATIENT"` or `"DOCTOR"` (uppercase) |
| `dateOfBirth` | `DateTime` | ❌ | Date of birth |
| `gender` | `string` | ❌ | `"MALE"` or `"FEMALE"` |
| `height` | `double` | ✅ | Height in cm (patients only) |
| `weight` | `double` | ✅ | Weight in kg (patients only) |

### JSON Serialization

```json
{
  "fullName": "string",
  "email": "string",
  "password": "string",
  "phoneNumber": "string",
  "role": "PATIENT",
  "dateOfBirth": "1990-05-15",
  "gender": "MALE",
  "height": 175.0,
  "weight": 70.0
}
```

> **Important:** `dateOfBirth` is formatted as `YYYY-MM-DD` (not ISO 8601 with time). The Flutter code manually formats: `"${year}-${month}-${day}"` with zero-padding.

### TypeScript Interface

```typescript
interface RegisterRequest {
  fullName: string;
  email: string;
  password: string;
  phoneNumber: string;
  role: 'PATIENT' | 'DOCTOR';
  dateOfBirth: string;  // "YYYY-MM-DD"
  gender: 'MALE' | 'FEMALE';
  height?: number;  // cm, patients only
  weight?: number;  // kg, patients only
}
```

---

## 5. PatientResponseModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`patient_response_model.dart`](file:///e:/side%20projects/gp_app/lib/models/patient_response_model.dart) |
| **Doctor usage** | Patient cards in doctor dashboard |
| **Patient usage** | Not used |
| **API responses** | `GET /doctor/patients/{doctorId}` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | `int` | ❌ | Patient backend ID |
| `fullName` | `string` | ❌ | Patient's full name |
| `email` | `string` | ❌ | Patient's email |
| `priority` | `string` | ❌ | Server-computed priority. Default: `"MEDIUM"` |
| `healthStatus` | `string` | ❌ | Server-computed health status. Default: `"UNKNOWN"` |
| `profileImageUrl` | `string` | ✅ | Profile image |
| `gender` | `string` | ✅ | `"MALE"` / `"FEMALE"` |
| `dateOfBirth` | `string` | ✅ | `"YYYY-MM-DD"` |
| `height` | `double` | ✅ | Height in cm |
| `weight` | `double` | ✅ | Weight in kg |

### Enums

**`priority`**: `"CRITICAL"` | `"HIGH"` | `"MEDIUM"` | `"LOW"`

**`healthStatus`**: `"CRITICAL"` | `"WARNING"` | `"NORMAL"` | `"UNKNOWN"`

### Computed Properties

| Property | Type | Logic |
|----------|------|-------|
| `age` | `int?` | Calculated from `dateOfBirth`: `now.year - dob.year` (adjusted for month/day) |

### TypeScript Interface

```typescript
type Priority = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
type HealthStatus = 'CRITICAL' | 'WARNING' | 'NORMAL' | 'UNKNOWN';

interface PatientResponse {
  id: number;
  fullName: string;
  email: string;
  priority: Priority;
  healthStatus: HealthStatus;
  profileImageUrl?: string | null;
  gender?: string | null;
  dateOfBirth?: string | null;  // "YYYY-MM-DD"
  height?: number | null;
  weight?: number | null;
}
```

---

## 6. PatientSearchModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`patient_search_model.dart`](file:///e:/side%20projects/gp_app/lib/models/patient_search_model.dart) |
| **Doctor usage** | Search results for adding patients |
| **Patient usage** | Not used |
| **API responses** | `GET /doctor/search/name`, `GET /doctor/search/phone` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | `int` | ❌ | Patient backend ID |
| `fullName` | `string` | ❌ | Patient name |
| `email` | `string` | ❌ | Patient email |
| `phoneNumber` | `string` | ✅ | Patient phone |

### TypeScript Interface

```typescript
interface PatientSearchResult {
  id: number;
  fullName: string;
  email: string;
  phoneNumber?: string | null;
}
```

---

## 7. DoctorInfoModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`doctor_info_model.dart`](file:///e:/side%20projects/gp_app/lib/models/doctor_info_model.dart) |
| **Doctor usage** | Not used |
| **Patient usage** | Shows assigned doctor info |
| **API responses** | `GET /patient/doctor/{patientId}` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | `int` | ❌ | Doctor backend ID |
| `fullName` | `string` | ❌ | Doctor's name |
| `email` | `string` | ❌ | Doctor's email |
| `profileImageUrl` | `string` | ✅ | Profile image |

### TypeScript Interface

```typescript
interface DoctorInfo {
  id: number;
  fullName: string;
  email: string;
  profileImageUrl?: string | null;
}
```

---

## 8. HealthMetricModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`health_metric_model.dart`](file:///e:/side%20projects/gp_app/lib/models/health_metric_model.dart) |
| **Doctor usage** | Patient vitals view, patient detail screen |
| **Patient usage** | Dashboard vitals, vitals history |
| **API responses** | `GET /iot/latest/{patientId}`, `GET /iot/history/{patientId}`, `POST /iot/upload/{patientId}` |

### Fields

| Field | Type | Nullable | Description | JSON key(s) |
|-------|------|----------|-------------|-------------|
| `id` | `int` | ❌ | Metric record ID | `id` |
| `heartRate` | `double` | ✅ | Heart rate in BPM | `heartRate` |
| `spo2` | `double` | ✅ | Blood oxygen saturation % | `spo2` |
| `batteryLevel` | `int` | ✅ | Device battery % | `batteryLevel` |
| `timestamp` | `DateTime` | ✅ | When measured | `measuredAt` or `timestamp` |
| `isCritical` | `bool` | ❌ | Whether reading is critical. Default: `false` | `critical` or `isCritical` |
| `priority` | `string` | ✅ | Server-computed priority | `priority` |
| `healthStatus` | `string` | ✅ | Server-computed health status | `healthStatus` |

### JSON Key Aliases

The model handles multiple JSON key formats from the backend:
- **Timestamp**: `json['measuredAt'] ?? json['timestamp']`
- **isCritical**: `json['critical'] ?? json['isCritical']` (Jackson serializes `boolean isCritical` as `critical` by default due to `is` prefix convention)

### Enums (same as PatientResponseModel)

**`priority`**: `"CRITICAL"` | `"HIGH"` | `"MEDIUM"` | `"NORMAL"` | `"LOW"`

**`healthStatus`**: `"CRITICAL"` | `"WARNING"` | `"NORMAL"` | `"UNKNOWN"`

### Computed Properties

| Property | Type | Value |
|----------|------|-------|
| `heartRateDisplay` | `string` | `heartRate?.toFixed(0) ?? '--'` |
| `spo2Display` | `string` | `spo2?.toFixed(0) ?? '--'` |
| `batteryLevelDisplay` | `string` | `batteryLevel?.toString() ?? '--'` |

### TypeScript Interface

```typescript
interface HealthMetric {
  id: number;
  heartRate?: number | null;
  spo2?: number | null;
  batteryLevel?: number | null;
  measuredAt?: string | null;  // ISO 8601 DateTime
  critical?: boolean;          // Note: backend uses "critical" not "isCritical"
  priority?: Priority | null;
  healthStatus?: HealthStatus | null;
}
```

---

## 9. MetricRequest

| Property | Value |
|----------|-------|
| **Flutter file** | [`metric_request.dart`](file:///e:/side%20projects/gp_app/lib/models/metric_request.dart) |
| **API requests** | `POST /iot/upload/{patientId}` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `heartRate` | `double` | ❌ | Heart rate BPM |
| `spo2` | `double` | ❌ | SpO2 percentage |
| `batteryLevel` | `int` | ❌ | Battery percentage (0-100) |

### TypeScript Interface

```typescript
interface MetricRequest {
  heartRate: number;
  spo2: number;
  batteryLevel: number;
}
```

---

## 10. DailySummaryModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`daily_summary_model.dart`](file:///e:/side%20projects/gp_app/lib/models/daily_summary_model.dart) |
| **Doctor usage** | Patient vitals charts |
| **Patient usage** | Dashboard vitals charts |
| **API responses** | `GET /iot/summary/{patientId}?days=N` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `date` | `DateTime` | ❌ | The date (parsed from `"YYYY-MM-DD"`) |
| `avgHeartRate` | `double` | ✅ | Average heart rate for the day |
| `avgSpo2` | `double` | ✅ | Average SpO2 for the day |
| `minHeartRate` | `double` | ✅ | Minimum heart rate |
| `maxHeartRate` | `double` | ✅ | Maximum heart rate |
| `minSpo2` | `double` | ✅ | Minimum SpO2 |
| `maxSpo2` | `double` | ✅ | Maximum SpO2 |
| `readingCount` | `int` | ❌ | Number of readings. Default: `0` |

### TypeScript Interface

```typescript
interface DailySummary {
  date: string;  // "YYYY-MM-DD"
  avgHeartRate?: number | null;
  avgSpo2?: number | null;
  minHeartRate?: number | null;
  maxHeartRate?: number | null;
  minSpo2?: number | null;
  maxSpo2?: number | null;
  readingCount: number;
}
```

---

## 11. HourlySummaryModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`hourly_summary_model.dart`](file:///e:/side%20projects/gp_app/lib/models/hourly_summary_model.dart) |
| **Doctor usage** | Patient vitals charts (24H mode) |
| **Patient usage** | Dashboard vitals charts (24H mode) |
| **API responses** | `GET /iot/summary/hourly/{patientId}?hours=N` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `dateTime` | `DateTime` | ❌ | The hour (parsed from ISO 8601 datetime) |
| `avgHeartRate` | `double` | ✅ | Average heart rate for the hour |
| `avgSpo2` | `double` | ✅ | Average SpO2 for the hour |
| `minHeartRate` | `double` | ✅ | Minimum heart rate |
| `maxHeartRate` | `double` | ✅ | Maximum heart rate |
| `minSpo2` | `double` | ✅ | Minimum SpO2 |
| `maxSpo2` | `double` | ✅ | Maximum SpO2 |
| `readingCount` | `int` | ❌ | Number of readings. Default: `0` |

### TypeScript Interface

```typescript
interface HourlySummary {
  dateTime: string;  // ISO 8601 DateTime "2024-01-15T10:00:00"
  avgHeartRate?: number | null;
  avgSpo2?: number | null;
  minHeartRate?: number | null;
  maxHeartRate?: number | null;
  minSpo2?: number | null;
  maxSpo2?: number | null;
  readingCount: number;
}
```

---

## 12. AppointmentModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`appointment_model.dart`](file:///e:/side%20projects/gp_app/lib/models/appointment_model.dart) |
| **Doctor usage** | Appointments list and management |
| **Patient usage** | Next appointment card on dashboard |
| **API responses** | `POST /appointments/schedule`, `GET /appointments/doctor/{doctorId}`, `GET /appointments/patient/{patientId}/next`, `PATCH /appointments/{id}/status` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | `int` | ✅ | Appointment ID (null when creating) |
| `doctorId` | `int` | ❌ | Doctor's backend ID |
| `doctorName` | `string` | ❌ | Doctor's display name |
| `patientId` | `int` | ❌ | Patient's backend ID |
| `patientName` | `string` | ❌ | Patient's display name |
| `appointmentDate` | `DateTime` | ❌ | Scheduled date/time |
| `reason` | `string` | ✅ | Appointment reason |
| `status` | `string` | ❌ | Appointment status. Default: `"SCHEDULED"` |

### Enums

**`status`**: `"SCHEDULED"` | `"CONFIRMED"` | `"CANCELLED"` | `"COMPLETED"`

### Date Parsing Note

The Flutter model handles backend datetime strings with or without `Z` suffix:
```dart
DateTime.parse(json['appointmentDate'].toString().endsWith('Z')
    ? json['appointmentDate']
    : '${json['appointmentDate']}Z')
```

### TypeScript Interface

```typescript
type AppointmentStatus = 'SCHEDULED' | 'CONFIRMED' | 'CANCELLED' | 'COMPLETED';

interface Appointment {
  id?: number | null;
  doctorId: number;
  doctorName: string;
  patientId: number;
  patientName: string;
  appointmentDate: string;  // ISO 8601 DateTime
  reason?: string | null;
  status: AppointmentStatus;
}
```

---

## 13. ChatMessageModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`chat_message_model.dart`](file:///e:/side%20projects/gp_app/lib/models/chat_message_model.dart) |
| **Doctor usage** | Chat with patients |
| **Patient usage** | Chat with doctor |
| **API responses** | `GET /chat/history/{userId1}/{userId2}`, WebSocket `/user/queue/messages` |

### Fields

| Field | Type | Nullable | Mutable | Description | JSON key |
|-------|------|----------|---------|-------------|----------|
| `senderId` | `int` | ❌ | ❌ | Sender's backend ID | `senderId` |
| `receiverId` | `int` | ❌ | ❌ | Receiver's backend ID | `receiverId` |
| `content` | `string` | ❌ | ❌ | Message text | `content` |
| `timestamp` | `DateTime` | ✅ | ❌ | When sent | `timestamp` |
| `senderName` | `string` | ✅ | ❌ | Sender's display name | `senderName` |
| `isRead` | `bool` | ❌ | ✅ | Read by receiver. Default: `false` | `read` |
| `isDelivered` | `bool` | ❌ | ✅ | Delivered to receiver. Default: `false` | `delivered` |

### JSON Key Differences

- **From backend**: `"read"` and `"delivered"` (not `"isRead"` / `"isDelivered"`)
- **To backend** (STOMP send): `"read"` and `"delivered"`

### TypeScript Interface

```typescript
interface ChatMessage {
  senderId: number;
  receiverId: number;
  content: string;
  timestamp?: string | null;  // ISO 8601 DateTime
  senderName?: string | null;
  read: boolean;
  delivered: boolean;
}
```

---

## 14. ChatContactModel

| Property | Value |
|----------|-------|
| **Flutter file** | [`chat_contact_model.dart`](file:///e:/side%20projects/gp_app/lib/models/chat_contact_model.dart) |
| **Doctor usage** | Chat conversations list |
| **Patient usage** | Chat conversations list |
| **API responses** | `GET /chat/conversations/{userId}` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `partnerId` | `int` | ❌ | Chat partner's backend ID |
| `partnerName` | `string` | ❌ | Partner's display name |
| `partnerEmail` | `string` | ❌ | Partner's email |
| `lastMessage` | `string` | ❌ | Last message content |
| `lastMessageTimestamp` | `DateTime` | ✅ | When last message was sent |
| `unreadCount` | `int` | ❌ | Number of unread messages |
| `partnerProfileImageUrl` | `string` | ✅ | Partner's profile image |

### TypeScript Interface

```typescript
interface ChatContact {
  partnerId: number;
  partnerName: string;
  partnerEmail: string;
  lastMessage: string;
  lastMessageTimestamp?: string | null;  // ISO 8601 DateTime
  unreadCount: number;
  partnerProfileImageUrl?: string | null;
}
```

---

## 15. NotificationItem

| Property | Value |
|----------|-------|
| **Flutter file** | [`notification_api_service.dart`](file:///e:/side%20projects/gp_app/lib/services/notification_api_service.dart#L6) (defined inline, not in models/) |
| **Doctor usage** | Notification bell/list |
| **Patient usage** | Notification bell/list |
| **API responses** | `GET /notifications/{userId}` |

### Fields

| Field | Type | Nullable | Description | JSON key |
|-------|------|----------|-------------|----------|
| `id` | `int` | ❌ | Notification ID | `id` |
| `userId` | `int` | ❌ | Owner user ID | `userId` |
| `type` | `string` | ❌ | Notification type | `type` |
| `title` | `string` | ❌ | Notification title | `title` |
| `body` | `string` | ❌ | Notification body | `body` |
| `relatedId` | `int` | ✅ | Related entity ID (e.g., sender ID for chat) | `relatedId` |
| `relatedName` | `string` | ✅ | Related entity name | `relatedName` |
| `isRead` | `bool` | ❌ | Whether read | `read` or `isRead` |
| `createdAt` | `DateTime` | ✅ | When created | `createdAt` |

### Notification Type Enums

| Type | Description |
|------|-------------|
| `CHAT` | New chat message |
| `APPOINTMENT_SCHEDULED` | New appointment |
| `APPOINTMENT_CONFIRMED` | Appointment confirmed |
| `PATIENT_ASSIGNED` | Patient linked to doctor |
| Other types | May exist — handle generically |

### TypeScript Interface

```typescript
type NotificationType = 'CHAT' | 'APPOINTMENT_SCHEDULED' | 'APPOINTMENT_CONFIRMED' | 'PATIENT_ASSIGNED' | string;

interface NotificationItem {
  id: number;
  userId: number;
  type: NotificationType;
  title: string;
  body: string;
  relatedId?: number | null;
  relatedName?: string | null;
  read: boolean;  // Backend key is "read"
  createdAt?: string | null;  // ISO 8601 DateTime
}
```

---

## 16. AiConsultResponse

| Property | Value |
|----------|-------|
| **Flutter file** | [`assessment_models.dart`](file:///e:/side%20projects/gp_app/lib/features/ai_assessment/models/assessment_models.dart#L90) |
| **Doctor usage** | View patient AI reports |
| **Patient usage** | View own AI reports, submit assessment |
| **API responses** | `POST /ai/consult/{patientId}`, `GET /ai/my-reports`, `GET /ai/history/{patientId}` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | `int` | ❌ | Report ID. Default: `0` |
| `patientId` | `int` | ❌ | Patient backend ID. Default: `0` |
| `patientInput` | `string` | ❌ | Stringified JSON of assessment answers |
| `patientRequestData` | `string` | ✅ | Raw request data |
| `patientName` | `string` | ✅ | Patient name |
| `patientAge` | `int` | ✅ | Patient age at time of assessment |
| `patientGender` | `string` | ✅ | Patient gender |
| `patientHeight` | `double` | ✅ | Patient height in cm |
| `patientWeight` | `double` | ✅ | Patient weight in kg |
| `aiReport` | `string` | ❌ | Markdown-formatted AI analysis report |
| `createdAt` | `DateTime` | ❌ | When created. Default: `DateTime.now()` |

### TypeScript Interface

```typescript
interface AiConsultResponse {
  id: number;
  patientId: number;
  patientInput: string;  // Stringified JSON
  patientRequestData?: string | null;
  patientName?: string | null;
  patientAge?: number | null;
  patientGender?: string | null;
  patientHeight?: number | null;
  patientWeight?: number | null;
  aiReport: string;  // Markdown content
  createdAt: string;  // ISO 8601 DateTime
}
```

---

## 17. DeviceReading (Local Only)

| Property | Value |
|----------|-------|
| **Flutter file** | [`device_reading.dart`](file:///e:/side%20projects/gp_app/lib/models/device_reading.dart) |
| **API responses** | None — local-only model for UDP sensor data |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `heartRate` | `double` | ❌ | Heart rate BPM (from Pulse Sensor) |
| `spo2` | `double` | ❌ | SpO2 % (actually MAX30105 HR — see notes) |
| `batteryLevel` | `int` | ❌ | Battery percentage (0-100) |
| `timestamp` | `DateTime` | ❌ | When reading was taken |

> **Note:** The `spo2` field carries a secondary heart rate reading from the MAX30105 sensor, NOT actual blood oxygen. The firmware would need to implement the red/IR ratio algorithm for real SpO2. The backend and UI both label it as "SpO2" however.

---

## 18. MeasurementModel (Local Only)

| Property | Value |
|----------|-------|
| **Flutter file** | [`measurement_model.dart`](file:///e:/side%20projects/gp_app/lib/models/measurement_model.dart) |
| **Local storage** | Hive (typeId: 1) |
| **API responses** | None — local cache only |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `type` | `string` | ❌ | `"HeartRate"` or `"SpO2"` |
| `value` | `double` | ❌ | Measured value |
| `unit` | `string` | ❌ | Unit of measurement (e.g., "bpm", "%") |
| `timestamp` | `DateTime` | ❌ | When measured |

---

## 19. SettingsModel (Local Only)

| Property | Value |
|----------|-------|
| **Flutter file** | [`settings_model.dart`](file:///e:/side%20projects/gp_app/lib/models/settings_model.dart) |
| **Local storage** | Hive (typeId: 2) |
| **API responses** | None — local preferences only |

### Fields

| Field | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| `isDarkMode` | `bool` | ❌ | `false` | Dark mode toggle |
| `enableNotifications` | `bool` | ❌ | `true` | Push notification toggle |
| `languageCode` | `string` | ❌ | `"en"` | Language: `"en"` or `"ar"` |

> **Note for web:** These are local preferences with no backend persistence. Store in `localStorage`.

---

## 20. PresenceStatus (Inline)

| Property | Value |
|----------|-------|
| **Flutter file** | [`presence_service.dart`](file:///e:/side%20projects/gp_app/lib/services/presence_service.dart#L72) |
| **API responses** | `GET /presence/{userId}` |

### Fields

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `online` | `bool` | ❌ | Whether user is currently online |
| `lastSeen` | `DateTime` | ✅ | Last activity timestamp |

### TypeScript Interface

```typescript
interface PresenceStatus {
  online: boolean;
  lastSeen?: string | null;  // ISO 8601 DateTime
}
```

---

## Date Format Summary

| Context | Format | Example |
|---------|--------|---------|
| `dateOfBirth` (register request) | `YYYY-MM-DD` | `"1990-05-15"` |
| `dateOfBirth` (user profile response) | `YYYY-MM-DD` | `"1990-05-15"` |
| `appointmentDate` (request) | ISO 8601 UTC | `"2024-01-20T14:00:00.000Z"` |
| `appointmentDate` (response) | ISO 8601 (may lack Z) | `"2024-01-20T14:00:00"` |
| `measuredAt` / `timestamp` | ISO 8601 | `"2024-01-15T10:30:00"` |
| `createdAt` | ISO 8601 | `"2024-01-15T10:30:00"` |
| `lastSeen` | ISO 8601 | `"2024-01-15T10:30:00"` |
| `lastMessageTimestamp` | ISO 8601 | `"2024-01-15T10:30:00"` |
| `date` (DailySummary) | `YYYY-MM-DD` | `"2024-01-15"` |
| `dateTime` (HourlySummary) | ISO 8601 | `"2024-01-15T10:00:00"` |

---

## ID Field Reference

| Field Name | Type | Description | Where Used |
|------------|------|-------------|------------|
| `id` (UserModel) | `string` | Firebase UID | **Not needed on web** |
| `backendId` (UserModel) | `int` | PostgreSQL ID | **Primary ID for ALL API calls** |
| `id` (from `/user/me`) | `int` | Same as backendId | User endpoints |
| `doctorId` | `int` | Doctor's backendId | Doctor/appointment/chat endpoints |
| `patientId` | `int` | Patient's backendId | Patient/IoT/appointment/AI endpoints |
| `userId` | `int` | Any user's backendId | Notifications/presence/chat endpoints |
| `userId1`, `userId2` | `int` | Chat participants' IDs | Chat history endpoint |
| `senderId`, `receiverId` | `int` | Message participants | Chat messages |
| `appointmentId` | `int` | Appointment record ID | Appointment status update |
| `notificationId` | `int` | Notification record ID | Notification management |

---

## Complete TypeScript Types File

```typescript
// ═══════════════════════════════════════════════════════════════
// Enums
// ═══════════════════════════════════════════════════════════════

export type Role = 'DOCTOR' | 'PATIENT';
export type Gender = 'MALE' | 'FEMALE';
export type Priority = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'NORMAL' | 'LOW';
export type HealthStatus = 'CRITICAL' | 'WARNING' | 'NORMAL' | 'UNKNOWN';
export type AppointmentStatus = 'SCHEDULED' | 'CONFIRMED' | 'CANCELLED' | 'COMPLETED';
export type NotificationType = 'CHAT' | 'APPOINTMENT_SCHEDULED' | 'APPOINTMENT_CONFIRMED' | 'PATIENT_ASSIGNED' | string;

// ═══════════════════════════════════════════════════════════════
// Request DTOs
// ═══════════════════════════════════════════════════════════════

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  fullName: string;
  email: string;
  password: string;
  phoneNumber: string;
  role: Role;
  dateOfBirth: string;  // "YYYY-MM-DD"
  gender: Gender;
  height?: number;
  weight?: number;
}

export interface MetricRequest {
  heartRate: number;
  spo2: number;
  batteryLevel: number;
}

export interface ScheduleAppointmentRequest {
  doctorId: number;
  patientId: number;
  appointmentDate: string;  // ISO 8601 UTC
  reason?: string;
}

export interface UpdateProfileRequest {
  fullName?: string;
  phoneNumber?: string;
  email?: string;
  password?: string;
  dateOfBirth?: string;
  gender?: Gender;
  height?: number;
  weight?: number;
  profileImageUrl?: string;
}

// ═══════════════════════════════════════════════════════════════
// Response DTOs
// ═══════════════════════════════════════════════════════════════

export interface AuthResponse {
  token: string;
}

export interface User {
  id: number;
  fullName: string;
  email: string;
  role: Role;
  phoneNumber?: string | null;
  dateOfBirth?: string | null;
  gender?: Gender | null;
  height?: number | null;
  weight?: number | null;
  profileImageUrl?: string | null;
}

export interface PatientResponse {
  id: number;
  fullName: string;
  email: string;
  priority: Priority;
  healthStatus: HealthStatus;
  profileImageUrl?: string | null;
  gender?: string | null;
  dateOfBirth?: string | null;
  height?: number | null;
  weight?: number | null;
}

export interface PatientSearchResult {
  id: number;
  fullName: string;
  email: string;
  phoneNumber?: string | null;
}

export interface DoctorInfo {
  id: number;
  fullName: string;
  email: string;
  profileImageUrl?: string | null;
}

export interface HealthMetric {
  id: number;
  heartRate?: number | null;
  spo2?: number | null;
  batteryLevel?: number | null;
  measuredAt?: string | null;
  critical?: boolean;
  priority?: Priority | null;
  healthStatus?: HealthStatus | null;
}

export interface DailySummary {
  date: string;
  avgHeartRate?: number | null;
  avgSpo2?: number | null;
  minHeartRate?: number | null;
  maxHeartRate?: number | null;
  minSpo2?: number | null;
  maxSpo2?: number | null;
  readingCount: number;
}

export interface HourlySummary {
  dateTime: string;
  avgHeartRate?: number | null;
  avgSpo2?: number | null;
  minHeartRate?: number | null;
  maxHeartRate?: number | null;
  minSpo2?: number | null;
  maxSpo2?: number | null;
  readingCount: number;
}

export interface Appointment {
  id?: number | null;
  doctorId: number;
  doctorName: string;
  patientId: number;
  patientName: string;
  appointmentDate: string;
  reason?: string | null;
  status: AppointmentStatus;
}

export interface ChatMessage {
  senderId: number;
  receiverId: number;
  content: string;
  timestamp?: string | null;
  senderName?: string | null;
  read: boolean;
  delivered: boolean;
}

export interface ChatContact {
  partnerId: number;
  partnerName: string;
  partnerEmail: string;
  lastMessage: string;
  lastMessageTimestamp?: string | null;
  unreadCount: number;
  partnerProfileImageUrl?: string | null;
}

export interface NotificationItem {
  id: number;
  userId: number;
  type: NotificationType;
  title: string;
  body: string;
  relatedId?: number | null;
  relatedName?: string | null;
  read: boolean;
  createdAt?: string | null;
}

export interface PresenceStatus {
  online: boolean;
  lastSeen?: string | null;
}

export interface AiConsultResponse {
  id: number;
  patientId: number;
  patientInput: string;
  patientRequestData?: string | null;
  patientName?: string | null;
  patientAge?: number | null;
  patientGender?: string | null;
  patientHeight?: number | null;
  patientWeight?: number | null;
  aiReport: string;
  createdAt: string;
}

// ═══════════════════════════════════════════════════════════════
// Paginated Response (Spring Page)
// ═══════════════════════════════════════════════════════════════

export interface Page<T> {
  content: T[];
  totalPages: number;
  totalElements: number;
  number: number;  // current page (0-indexed)
  size: number;
}
```
