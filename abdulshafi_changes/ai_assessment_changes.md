# AI Assessment & Report History Updates

## 1. AI Assessment Report UI Redesign
- Replaced the raw JSON display of AI Reports with a professional, card-based UI (`ReportResultScreen`).
- Added robust JSON parsing, Arabic translation of medical keys, and smart filtering of empty/null values (`ReportFormatter`, `ReportSectionCard`).
- Implemented Arabic PDF Export capability using `pdf` and `printing` packages (`ReportPdfExporter`).

## 2. Patient AI Report History
- Updated the floating robot icon on the Patient Dashboard to show a Bottom Sheet instead of navigating directly.
- The Bottom Sheet dynamically checks for previous reports and offers to start a new assessment or view history.
- Implemented `ReportHistoryScreen` to display a clean list of past reports without exposing raw content in the list view.

## 3. Doctor AI Report Access
- Added a new endpoint method `AiAssessmentApiService.getPatientReportsForDoctor` to fetch reports for specific patients (`GET /api/ai/history/{patientId}`).
- Added a new button `عرض تقارير التقييم` in the Doctor's `PatientDetailScreen` to access a patient's report history.
- Re-used `ReportHistoryScreen` and `ReportResultScreen` with dynamic routing arguments (`isDoctorView`, `patientNameOverride`) to support both patient self-view and doctor view while keeping navigation isolated.

## 4. Dependencies & Configurations
- Added `pdf: ^3.11.1` and `printing: ^5.13.4` dependencies.
- Updated `ApiConfig` with latest network host settings.
- Added `/docs` for AI APIs documentation.
- General cleanup of deprecated usages (like `.withOpacity` -> `.withValues`) in modified files to keep `flutter analyze` fully clean.

## 5. Git Commits Included
The changes have been broken down and committed into logical blocks in Git:
1. `chore: add pdf and printing dependencies for AI reports`
2. `feat: redesign AI assessment report display and PDF export`
3. `feat: implement AI report history for patients and doctors`
4. `chore: update api config, docs and localizations`
