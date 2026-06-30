# MISSING_INFO_AND_RISKS.md — Unknowns, Risks & Open Questions

> Everything an AI agent or developer must verify with the backend or
> stakeholders **before** shipping the doctor web app. Items here are
> things the Flutter app could not reveal on its own.

---

## 1. Critical unknowns (must verify before launch)

### 1.1 HTTPS for the backend

The backend currently runs on plain HTTP:
`http://smart-medical-api-env.eba-jxdmccmi.us-east-1.elasticbeanstalk.com/api`.

**Risk:** modern browsers block "mixed content" — an HTTPS web app
cannot call HTTP endpoints. Login pages over HTTP are also flagged
"Not Secure" by Chrome / Safari.

**Action needed:**
- Confirm whether the backend can be exposed over HTTPS (Elastic
  Beanstalk + ACM / ELB listener on 443).
- If not, either deploy the web app on HTTP (insecure, not recommended)
  or proxy through Next.js API routes / Cloudflare.

### 1.2 Refresh-token strategy

Mobile stores **plaintext email + password** in secure storage and
re-logs in on 401/403 to obtain a fresh JWT.

**Risk:** localStorage is plain text on the web; storing the password
would be a vulnerability.

**Action needed:**
- Ideally: backend adds a real refresh token endpoint (e.g., `/auth/refresh`
  with an httpOnly cookie). Otherwise:
- Web v1 will force re-login on every 401/403. This is acceptable but
  a worse UX than the mobile app.

### 1.3 CORS configuration

The backend must allow the web app's origin (e.g.,
`https://doctor.nabda.app`) for:
- `Origin` headers on REST.
- `OPTIONS` preflight for `Authorization` header.
- WebSocket/SockJS handshake.

**Action needed:** ask the backend team to add the web app domain to the
CORS allowlist + Spring `WebSocketMessageBrokerConfigurer.setAllowedOrigins`.

### 1.4 Firebase web configuration

Mobile uses `lib/firebase_options.dart` for Android/iOS. The
**web platform** needs its own `firebaseConfig` (different `apiKey`,
`appId`, etc.).

**Action needed:**
- Run `flutterfire configure --platforms=web` (or generate manually in
  Firebase console → Project Settings → Web app).
- Add the deployment domain to Firebase Auth → Authorized Domains.

### 1.5 WebSocket payload shapes — system events

The mobile code handles these event types but doesn't fully document
their extra fields (only `type` is used):
- `PATIENT_ASSIGNED`, `PATIENT_REMOVED`.
- `APPOINTMENT_SCHEDULED`, `APPOINTMENT_CONFIRMED`,
  `APPOINTMENT_CANCELLED`, `APPOINTMENT_COMPLETED`.

**Action needed:** confirm with the backend the full JSON schema of each
event (do they carry `appointmentId`, `patientId`, etc.?). The web app
can then surface deep-linkable notifications.

### 1.6 STOMP destinations for sending

Mobile publishes only to `/app/chat.send`. If the backend supports other
client-published destinations (e.g. typing indicators), they are not
exercised by the mobile code.

**Action needed:** confirm whether any send-destinations exist beyond
`/app/chat.send`.

### 1.7 `/notifications/{userId}` pagination contract

Mobile defensively handles both:
- Spring Page wrapper: `{ content: [...] }`.
- Raw array: `NotificationItem[]`.

**Action needed:** confirm which the backend actually returns (Spring
`Page<NotificationItem>` is most likely). The web app should support both
to be safe but should pick the canonical one for typing.

### 1.8 `priority` vs `healthStatus` semantics

`PatientResponse` carries both `priority` (CRITICAL/HIGH/MEDIUM/NORMAL/LOW)
and `healthStatus` (CRITICAL/WARNING/NORMAL/UNKNOWN). They overlap but
aren't identical.

**Action needed:** verify which field is canonical for sorting on the
backend, and whether `priority` is used elsewhere (e.g., a backend rule
that pushes "HIGH" patients to the top of `/doctor/patients`).

### 1.9 SpO₂ value semantics

The mobile code is explicit (`lib/models/device_reading.dart`) that the
current firmware does not produce real SpO₂ — the `spo2` field carries
HR via the MAX30105 IR sensor. The doctor dashboard happily displays it
as "Blood Oxygen".

**Risk:** clinical misinterpretation.

**Action needed:** decide whether the web app should:
- Re-label the field as "MAX30105 Reading" until firmware ships true SpO₂.
- Show a small "ⓘ" disclaimer near SpO₂ when displayed to the doctor.

### 1.10 Localization gaps

`AppLocalizations.of(context)?.get('key')` returns `null` when a key is
missing. Mobile silently shows `null` in places (visible in the codebase
via `?? '<fallback>'`).

**Action needed:** when copying the EN/AR maps from
`lib/utils/app_localizations.dart`, audit for missing AR translations
and add them. Some keys appear English-only in mobile (e.g., the date
pill on the dashboard).

### 1.11 Image upload size limits

Mobile sends profile images as base64 data URIs inside JSON.
This is wasteful for large images.

**Action needed:** verify the backend's max request body size on
`PUT /user/me`. Web should crop+resize to ≤ 512×512 and JPEG-quality 85
before encoding, matching what the mobile cropper effectively produces.

---

## 2. Medium-risk items

### 2.1 Doctor-only role enforcement

Backend currently relies on JWT role claims. If a non-doctor logs into
the web app, mobile-style auto-routing would still hit a Patient
dashboard. The web app must:
- Read role from `/user/me`.
- Refuse non-doctor accounts with a clear error + sign-out.

### 2.2 STOMP subscription on `/topic/vitals/{currentUserId}`

The mobile code subscribes using the current user's ID. For a doctor,
this implies the backend broadcasts vitals to a topic keyed by
**doctor ID** (covering all their assigned patients). This needs to be
confirmed — if instead the topic is per-patient, the web app must
subscribe to `/topic/vitals/{patientId}` for each visible patient.

**Action needed:** confirm with backend whether `/topic/vitals/{userId}`
is keyed by doctor (recommended) or by patient.

### 2.3 Time zones

Mobile uses `toLocal()` for display and `toUtc()` for sending appointment
times. The web should follow the same pattern. Verify the backend stores
in UTC (mobile assumes so).

### 2.4 Long-running AI consult requests

Submitting an AI consult uses a 6-minute receive timeout. Browsers also
have limits, especially on mobile. The web app doesn't submit consults
(read-only), but if a feature is ever added, the long-poll pattern needs
review (Server-Sent Events / WebSocket job progress would be better).

### 2.5 Background activity (mobile-only)

Mobile keeps a foreground service running on Android for vitals. The web
has no equivalent. Doctors who close the tab won't receive heads-up
alerts. Either:
- Add web push notifications (FCM web SDK) — needs HTTPS + backend
  `token` endpoint adaptation.
- Accept that doctors only get alerts while the tab is open.

### 2.6 Avatar caching strategy

Mobile caches base64-decoded bytes in a 30-entry LRU. The web doesn't
need this (browsers cache `data:` URIs implicitly), but rendering many
data-URIs in a list can hurt FPS — consider lazy-mounting avatars or
using `<img loading="lazy">`.

### 2.7 Doctor profile fields not used by backend

`UserModel` carries `licenseNumber`, but the backend `RegisterRequest`
schema (see `register_request.dart`) does **not** include it. The mobile
form never sends it. Verify whether the backend has a license field at
all; if not, hide it on the web doctor profile.

---

## 3. Low-risk / future work

### 3.1 PDF export
`lib/features/ai_assessment/utils/report_pdf_exporter.dart` is mobile-only.
Web parity can use `pdfmake` with embedded Cairo TTF. Defer to v2.

### 3.2 PWA / installable web app
Optional. Web push + service worker would let doctors install the app to
their dock/taskbar. Defer to v2.

### 3.3 Per-card animated backgrounds
The heartbeat wave / bubbles / charging wave on VitalCard add a "wow"
factor on mobile but are expensive to port. Decide with the design
stakeholder.

### 3.4 Multi-tab WebSocket sharing
A SharedWorker can prevent N tabs from holding N WebSocket connections.
Defer to v2 unless backend rate-limits become an issue.

### 3.5 Real-time presence ergonomics
Mobile polls presence every 15 s in chat. A push model (presence updates
on the system queue) would be cheaper. Verify with backend.

---

## 4. Decisions the team must make before coding

| # | Decision | Recommendation |
|---|----------|----------------|
| 1 | Backend HTTPS yes/no | Switch to HTTPS before launch. |
| 2 | Refresh-token endpoint | Add a `/auth/refresh` endpoint; otherwise force re-login. |
| 3 | Stack: Next.js vs Vite+React | Next.js (App Router) for SEO + middleware. |
| 4 | SSR vs CSR | CSR is enough (auth-protected app). |
| 5 | Charts library | recharts (free, good DX). |
| 6 | Toast library | `sonner` (or build custom matching `AnimatedToast`). |
| 7 | Hosting | Vercel/Netlify for the front-end; backend on existing Elastic Beanstalk. |
| 8 | Web push | Defer to v2. |
| 9 | Internationalization library | `i18next` for parity with the existing key/value map. |
| 10 | Avatar storage | Keep base64 in DB (parity) OR move to S3 + URL (future-proof). |

---

## 5. Items to clarify with the original Flutter team

- Is the backend repository accessible? Confirm the canonical OpenAPI
  spec / Spring DTOs to avoid wire-format drift.
- Who owns the wearable firmware that broadcasts UDP? When will real
  SpO₂ ship?
- Are there RBAC roles beyond DOCTOR / PATIENT (e.g., ADMIN)?
- What are the rate limits on REST and STOMP?
- Is there a staging environment for the doctor web app to integrate
  against without affecting production patients?

---

## 6. Production-readiness checklist (carried forward from README §"Current Limitations")

- [ ] State management hardening (Riverpod/BLoC on mobile, TanStack Query on web).
- [ ] Stronger automated test coverage.
- [ ] Offline support (web: service worker fallback for read-only views).
- [ ] Stricter env-flavor config (dev / staging / prod base URLs).
- [ ] Logging + monitoring (Sentry, Datadog, etc.).
- [ ] Accessibility audit (WCAG 2.1 AA at minimum).
- [ ] Privacy review for medical data handling (e.g., HIPAA / Egypt PDPL
      applicability).
- [ ] Security review: JWT storage, CORS, CSP, dependency pinning.
- [ ] Performance budget (< 200 KB JS initial, < 2 s LCP).
- [ ] Backup + recovery story for patient avatars stored as base64.
