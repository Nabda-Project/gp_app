# DESIGN_SYSTEM.md — NABDA Visual Design System (Exhaustive)

> This is the canonical reference for rebuilding NABDA's design identity
> in React/Next.js/Tailwind. Every value is sourced directly from the
> Flutter codebase with explicit `path:line` citations. The goal is full
> visual parity with the existing mobile app.
>
> **Conventions used in this doc**
> - All colors are expressed as 8-digit hex `#RRGGBBAA` when they include
>   alpha, otherwise `#RRGGBB`.
> - Spacing is given in CSS `px` (Flutter logical pixels map 1:1 to CSS
>   px in web at default zoom).
> - "Mobile-specific" markers ⚠️ flag patterns that need a web rework.

---

## 1. Color tokens

### 1.1 Core brand palette (canonical, from `lib/utils/constants.dart:3-33`)

| Token            | Value (hex)         | Flutter constant            | Source                              |
|------------------|---------------------|-----------------------------|-------------------------------------|
| `primaryBlue`    | `#407BFF`           | `AppColors.primaryBlue`     | `lib/utils/constants.dart:4`        |
| `secondaryBlue`  | `#00B4D8`           | `AppColors.secondaryBlue`   | `lib/utils/constants.dart:5`        |
| `darkBlue`       | `#03045E`           | `AppColors.darkBlue`        | `lib/utils/constants.dart:6`        |
| `background`     | `#F8FAFC`           | `AppColors.background`      | `lib/utils/constants.dart:7`        |
| `white`          | `#FFFFFF`           | `AppColors.white`           | `lib/utils/constants.dart:8`        |
| `grey`           | `#94A3B8`           | `AppColors.grey`            | `lib/utils/constants.dart:9`        |
| `lightGrey`      | `#E2E8F0`           | `AppColors.lightGrey`       | `lib/utils/constants.dart:10`       |
| `accentTeal`     | `#00BFA5`           | `AppColors.accentTeal`      | `lib/utils/constants.dart:11`       |
| `error`          | `#E53935`           | `AppColors.error`           | `lib/utils/constants.dart:12`       |
| `gradientStart`  | `#407BFF`           | `AppColors.gradientStart`   | `lib/utils/constants.dart:15`       |
| `gradientEnd`    | `#00B4D8`           | `AppColors.gradientEnd`     | `lib/utils/constants.dart:16`       |
| `cardGlow`       | `#407BFF1A` (0x1A=10%)| `AppColors.cardGlow`      | `lib/utils/constants.dart:17`       |

Recommended Tailwind tokens (CSS variables):

```css
:root {
  --color-primary:        #407BFF;
  --color-primary-50:     #EBF1FF;   /* derived (used in assessment surface) */
  --color-primary-100:    #B3CDFF;   /* derived (assessment primaryLight) */
  --color-primary-700:    #2D5FC4;   /* derived (assessment primaryDark) */
  --color-secondary:      #00B4D8;
  --color-dark-blue:      #03045E;
  --color-background:     #F8FAFC;
  --color-surface:        #FFFFFF;
  --color-grey:           #94A3B8;
  --color-light-grey:     #E2E8F0;
  --color-accent-teal:    #00BFA5;
  --color-error:          #E53935;
}
```

### 1.2 Material colors used directly (NOT in `AppColors`)

These show up inline across the doctor screens. Treat them as semantic
tokens; a web build should expose them as named CSS variables.

| Token              | Hex          | Source(s)                                                                                  |
|--------------------|--------------|--------------------------------------------------------------------------------------------|
| `green`            | `#4CAF50` (Material default) `Colors.green` | Doctor appointments – complete button, vitals "Normal" status (`doctor_appointments_screen.dart:430`, `patient_vitals_screen.dart:1067`) |
| `red`              | `#F44336` `Colors.red` | Cancelled appointment status (`doctor_appointments_screen.dart:430`)             |
| `redAccent`        | `#FF5252` `Colors.redAccent` | Patient card HR chip icon (`patient_card.dart:122`), appointment "Cancel" label (`doctor_appointments_screen.dart:608,612`) |
| `orange`           | `#FF9800` `Colors.orange` | Warning state (PatientCard, vitals statuses, banner) (`patient_card.dart:33`, `patient_vitals_screen.dart:214,1065`, doctor appointments time icon `:577`) |
| `purple`           | `#9C27B0` `Colors.purple` | Today's appointments stat card (`doctor_dashboard_screen.dart:900`), notification type APPOINTMENT_SCHEDULED (`notifications_screen.dart:269`) |
| `lightBlue`        | `#03A9F4` `Colors.lightBlue` | Patient detail SpO₂ VitalCard tint (`patient_detail_screen.dart:223`)       |
| `black87`          | `#DD000000` (≈88% black) | DOB picker selected text (`auth_screen.dart:998`)                             |

### 1.3 Status / health palette (from `StatusCard` + ad-hoc usage)

| State        | Hex          | Use                                  | Source                                  |
|--------------|--------------|--------------------------------------|-----------------------------------------|
| `critical`   | `#D32F2F`    | StatusCard CRITICAL accent           | `lib/widgets/reusable/status_card.dart:51` |
| `warning`    | `#FF9800` (Material orange) | StatusCard WARNING + warning chips | `lib/widgets/reusable/status_card.dart:53` |
| `normal`     | `#00C853`    | StatusCard NORMAL accent             | `lib/widgets/reusable/status_card.dart:55` |
| `unknown`    | `#94A3B8` (grey) | StatusCard UNKNOWN              | `lib/widgets/reusable/status_card.dart:58` |

### 1.4 Toast / feedback palette (from `AnimatedToast`)

| Type     | Hex        | Source                                              |
|----------|------------|-----------------------------------------------------|
| success  | `#00E676`  | `lib/widgets/reusable/animated_toast.dart:69`       |
| error    | `#FF5252`  | `lib/widgets/reusable/animated_toast.dart:71`       |
| warning  | `#FFAB40`  | `lib/widgets/reusable/animated_toast.dart:73`       |
| info     | `#448AFF`  | `lib/widgets/reusable/animated_toast.dart:75`       |
| toast bg light | `#FFFFFF` | `:62`                                            |
| toast bg dark  | `#1E1E1E` | `:62` (only used if device is dark; not used by web doctor app) |

### 1.5 Vital card gradients (used in `patient_vitals_screen.dart`)

| Card     | Gradient                       | Source                                        |
|----------|--------------------------------|-----------------------------------------------|
| Heart Rate (live) | `#FF5252` → `#FF1744` (135°)| `patient_vitals_screen.dart:367-371`     |
| SpO₂ (live)       | `#2196F3` → `#1565C0` (135°)| `patient_vitals_screen.dart:408-412`     |
| Battery (live)    | white card with `battColor` border (`green/orange/red/grey`) | `:438-451`         |
| Chart container background | `#FDFDFF` → `#F5F7FC` (135°) | `patient_vitals_screen.dart:493-497` |
| Chart tooltip bg  | `#1E1E2E`                  | `:747`                                       |
| HR series color   | `#FF5252`                  | `:593, 616, 525`                             |
| SpO₂ series color | `#2196F3`                  | `:603, 617, 527`                             |

### 1.6 Chat-screen palette (`patient_chat_screen.dart`)

| Element        | Color                                | Source     |
|----------------|--------------------------------------|------------|
| Page bg (under decorative circles) | `#F4F7FA` | `:344`     |
| Decorative circle 1 | `primaryBlue × 4%` (`alpha: 0.04`) | `:355`     |
| Decorative circle 2 | `accentTeal × 3%` (`alpha: 0.03`) | `:367`     |
| Decorative circle 3 | `primaryBlue × 2%` (`alpha: 0.02`) | `:379`     |
| My-message bubble bg | `primaryGradient`              | `:615`     |
| Other-message bubble bg | `white`                     | `:616`     |
| Other-message border | `grey × 10%`                   | `:633`     |
| My-message text   | `Colors.white`                    | `:644`     |
| Other-message text | `darkBlue`                      | `:644`     |
| Timestamp on my bubble | `white × 80%`                | `:658`     |
| Timestamp on other bubble | `grey × 80%`              | `:659`     |
| Read tick icon (eye) | `Colors.white`                 | `:667-669` |
| Delivered icon       | `white × 90%`                  | `:670-673` |
| Sent icon            | `white × 70%`                  | `:674-677` |
| Send button shadow   | `primaryBlue × 30%`            | `:512`     |
| Input border         | `lightGrey × 50%`              | `:472`     |
| Input shadow         | `black × 5%`                   | `:466`     |
| Date separator chip bg | `grey × 8%`                  | `:560`     |
| Date separator chip text | `grey × 70%`               | `:566`     |

### 1.7 Auth screen extras (`auth_screen.dart`)

| Element                  | Color       | Source         |
|--------------------------|-------------|----------------|
| Form field background    | `#F5F7FA`   | `:502, 926, 983, 1013` |
| Google button background | `#F2F2F2`   | `:825`         |
| Google text              | `#1F1F1F`   | `:858`         |
| Role toggle track        | `#F5F7FA`   | `:611`         |
| Selected role text       | `primaryBlue` | `:899`       |
| Unselected role text     | `grey`      | `:899`         |

### 1.8 Profile-screen extras (`profile_screen.dart`)

| Element                       | Color            | Source       |
|-------------------------------|------------------|--------------|
| Hero gradient app bar (280px) | `primaryGradient`| `:563`       |
| App-bar logout pill bg        | `white × 15%`    | `:600`       |
| Avatar border ring            | `white × 50%`    | `:633`       |
| Avatar bg fallback            | `white × 20%`    | `:642`       |
| Role badge bg                 | `white × 20%`    | `:709`       |
| Profile-card text input bg    | `#F5F7FA`        | `:502`       |
| Tile chevron                  | `grey`           | `:1030`      |
| Camera badge bg (avatar)      | `accentTeal`     | `:666`       |
| Divider                       | `lightGrey × 50%`| `:991`       |
| Info-tile leading icon bg     | `primaryBlue × 8%` | `:951`     |

### 1.9 Assessment palette (`lib/features/ai_assessment/widgets/assessment_theme.dart`)

Used on doctor-visible "AI Report History" header and report tiles
(doctor enters with `isDoctorView=true`, RTL forced):

| Token             | Hex        | Source                                              |
|-------------------|------------|-----------------------------------------------------|
| `primary`         | `#407BFF`  | `assessment_theme.dart:7`                           |
| `primaryDark`     | `#2D5FC4`  | `:8`                                                |
| `primaryLight`    | `#B3CDFF`  | `:9`                                                |
| `primarySurface`  | `#EBF1FF`  | `:10`                                               |
| `accent`          | `#00B4D8`  | `:13`                                               |
| `accentLight`     | `#D0F4FF`  | `:14`                                               |
| `background`      | `#F0F5FF`  | `:17`                                               |
| `cardBg`          | `#FFFFFF`  | `:18`                                               |
| `surfaceLight`    | `#F8FAFF`  | `:19`                                               |
| `textPrimary`     | `#1E293B`  | `:22`                                               |
| `textSecondary`   | `#64748B`  | `:23`                                               |
| `textMuted`       | `#94A3B8`  | `:24`                                               |
| `success`         | `#10B981`  | `:27`                                               |
| `warning`         | `#F59E0B`  | `:28`                                               |
| `danger`          | `#EF4444`  | `:29`                                               |
| `dangerLight`     | `#FEE2E2`  | `:30`                                               |
| `selected`        | `#407BFF`  | `:33`                                               |
| `selectedBg`      | `#EBF1FF`  | `:34`                                               |
| `unselected`      | `#E2E8F0`  | `:35`                                               |

### 1.10 Notification type → color map (`notifications_screen.dart:264-279`)

| Type                       | Color           | Source       |
|----------------------------|-----------------|--------------|
| `CHAT`                     | `primaryBlue`   | `:267`       |
| `APPOINTMENT_SCHEDULED`    | `Colors.purple` | `:269`       |
| `APPOINTMENT_CONFIRMED`    | `accentTeal`    | `:271`       |
| `APPOINTMENT_CANCELLED`    | `error`         | `:273`       |
| `APPOINTMENT_COMPLETED`    | `Colors.green`  | `:275`       |
| default (unknown)          | `grey`          | `:277`       |

### 1.11 Battery thresholds → color (`patient_vitals_screen.dart:439-445`)

```
batt > 50  → Colors.green
batt > 20  → Colors.orange
batt > 0   → Colors.red
batt null  → grey
```

### 1.12 Alpha conventions encountered in code

Mobile uses `Color.withValues(alpha: x)` heavily. Common opacity stops
to replicate exactly:

| Use                                         | Alpha          |
|---------------------------------------------|----------------|
| Background tint chips (icon container)      | 0.05–0.10      |
| Hover/light backdrop                        | 0.10           |
| Section divider                             | 0.04–0.06 (with `black`) |
| Decorated background circles (page-level)   | 0.02–0.04      |
| Status pulse glow shadow                    | 0.10–0.18      |
| Gradient button shadow                      | 0.25–0.35      |
| Toast border                                | 0.10           |
| Toast colored shadow                        | 0.20           |
| Avatar fallback bg                          | `primaryBlue × 0.10` |

For Tailwind, expose these as `primary/10`, `primary/25`, etc. (Tailwind
v3+ supports `text-primary/40`).

### 1.13 Disabled states

Mobile relies on Flutter's default disabled colors for buttons (greyed
text + reduced opacity). Specifically:

- `CustomButton` (loading): `onPressed: null` ⇒ Material disables the
  button. The gradient container is still rendered but tap is ignored;
  loading-state shows a white 20×20 spinner inside.
- `ElevatedButton`: when `onPressed: null`, Flutter applies
  `Colors.black12` to fg and `Colors.black26` to bg. The web should
  mirror this with `opacity: 0.5; cursor: not-allowed; pointer-events: none;`
  on a button — or use `aria-disabled="true"`.
- Text fields don't have an explicit disabled state in code; the web
  should expose one via Tailwind `disabled:` modifier (e.g.
  `disabled:bg-[#F5F7FA] disabled:text-grey/60`).

### 1.14 Gradients (full list)

| Name                | Colors                                  | Direction               | Source                                      |
|---------------------|-----------------------------------------|-------------------------|---------------------------------------------|
| `primaryGradient`   | `#407BFF` → `#00B4D8`                   | TopLeft → BottomRight   | `constants.dart:29`                         |
| Heart-rate live card| `#FF5252` → `#FF1744`                   | TopLeft → BottomRight   | `patient_vitals_screen.dart:367`            |
| SpO₂ live card      | `#2196F3` → `#1565C0`                   | TopLeft → BottomRight   | `patient_vitals_screen.dart:408`            |
| Chart container bg  | `#FDFDFF` → `#F5F7FC`                   | TopLeft → BottomRight   | `patient_vitals_screen.dart:494`            |
| Forgot-password icon| `primaryBlue × 15%` → `× 5%`            | TopLeft → BottomRight   | `auth_screen.dart:260-263`                  |
| Logout-dialog icon  | `error × 10%` → `× 5%`                  | TopLeft → BottomRight   | `logout_dialog.dart:77-83`                  |
| Profile edit button | `#407BFF` → `#00B4D8`                   | CenterLeft → CenterRight| `profile_screen.dart:750-752`               |
| Search-result avatar (assign sheet) | `primaryBlue × 15%` → `secondaryBlue × 10%` | TopLeft → BottomRight | `assign_patient_sheet.dart:662-667` |
| AlertCard           | `color × 10%` → `× 5%`                  | (Linear, no axis)       | `alert_card.dart:27-29`                     |
| Assessment header   | `#407BFF` → `#00B4D8`                   | TopLeft → BottomRight   | `assessment_theme.dart:38-42`               |
| Assessment loading  | `#407BFF` → `#00B4D8` → `#1E3A5F`       | TopCenter → BottomCenter| `assessment_theme.dart:56-60`               |
| Assessment danger   | `#EF4444` → `#F87171`                   | TopLeft → BottomRight   | `assessment_theme.dart:50-54`               |
| Assessment card     | `#407BFF` → `#5B9BFF`                   | TopLeft → BottomRight   | `assessment_theme.dart:44-48`               |

### 1.15 Shadows (full list)

| Use                    | Shadow                                                  | Source                                  |
|------------------------|--------------------------------------------------------|------------------------------------------|
| Default card           | `0 8px 20px primaryBlue × 8%`                          | `constants.dart:20-26` (`AppColors.cardShadow`) |
| Status card pulsing    | `0 6px 20px statusColor × (10–18%)` (sin pulse 2.5s)   | `status_card.dart:96-99`                 |
| Patient card           | `0 4px 12px statusColor × 10%`                          | `patient_card.dart:58-62`                |
| Bottom nav             | `0 10px 30px primaryBlue × 15%`                         | `custom_bottom_nav.dart:27-30`           |
| Search field           | `0 2px 10px black × 5%`                                 | doctor_dashboard `:1476-1478`            |
| Chat avatar in app bar | `0 3px 8px primaryBlue × 15%`                           | `patient_chat_screen.dart:283-286`       |
| My-message bubble      | `0 4px 10px primaryBlue × 6%`                           | `patient_chat_screen.dart:624-629`       |
| Other-message bubble   | `0 4px 10px black × 6%`                                 | `patient_chat_screen.dart:625-629`       |
| Input row              | `0 5px 15px black × 5%`                                 | `patient_chat_screen.dart:466-469`       |
| Send button            | `0 4px 12px primaryBlue × 30%`                          | `patient_chat_screen.dart:511-515`       |
| Appointment card       | `0 8px 15px darkBlue × 5%`                              | `doctor_appointments_screen.dart:441-445`|
| Appointment icon orb   | `0 3px 8px statusColor × 20%`                           | `doctor_appointments_screen.dart:468-471`|
| Notification tile      | `0 2px 8px black × 4%`                                  | `notifications_screen.dart:375-378`      |
| Profile edit button    | `0 4px 12px primaryBlue × 25%`                          | `profile_screen.dart:756-762`            |
| Profile section card   | `0 4px 10px black × 5%`                                 | `profile_screen.dart:910-914`            |
| Profile option tile    | `0 2px 4px black × 5%`                                  | `profile_screen.dart:1007-1011`          |
| AssignPatient tile     | `0 2px 8px black × 4%`                                  | `assign_patient_sheet.dart:639-643`      |
| Assign Sheet result avatar | `0 2px 8px primaryBlue × 25%`                       | `assign_patient_sheet.dart:748-755`      |
| Logout dialog elevation | `elevation: 16` (Material)                             | `logout_dialog.dart:62`                  |
| NoInternet icon glow   | `0 0 30px primaryBlue × 20% spread 10`                  | `no_internet_view.dart:71-77`            |
| ServerDown icon glow   | `0 0 20px redAccent × 30% spread 5`                     | `server_down_view.dart:142-147`          |
| AppLogo                | `0 10px 20px primaryBlue × 20%`                         | `app_logo.dart:29-33`                    |
| Vital card             | `0 6px 16px color × 12%`                                | `vital_card.dart:71-75`                  |
| Stat card              | `0 4px 10px color × 10%`                                | `stat_card.dart:58-63`                   |

For Tailwind, define `shadow-card`, `shadow-card-status`,
`shadow-button-primary`, etc. The arbitrary-value syntax works:
`shadow-[0_8px_20px_rgba(64,123,255,0.08)]`.

---

## 2. Typography

### 2.1 Font families

| Family | Where defined / used | Source |
|--------|----------------------|--------|
| `Roboto` (default) | Set globally as `fontFamily: 'Roboto'` on the theme | `lib/theme/app_theme.dart:9` |
| `Cairo`            | Applied explicitly to Arabic-heavy UI: "View AI reports" button, AI report-history headings/tiles | `patient_detail_screen.dart:272`, `report_history_screen.dart:123-128, 208-209, 219-221, 240-243, 273-274, 281-283` |

Web stack to load (via Google Fonts):

```css
@import url('https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;600;700;800&family=Cairo:wght@400;500;600;700;800&display=swap');

:root {
  --font-sans: 'Roboto', 'Cairo', system-ui, -apple-system, 'Segoe UI', sans-serif;
  --font-arabic: 'Cairo', 'Roboto', sans-serif;
}

html[lang='ar'] { font-family: var(--font-arabic); direction: rtl; }
```

### 2.2 Theme-level type scale (`lib/theme/app_theme.dart:19-32`)

| Role          | Font size | Weight (Flutter) | Color       | Source |
|---------------|-----------|------------------|-------------|--------|
| `displayLarge`| 32        | `FontWeight.bold` (≈700) | `darkBlue`  | `:21-24` |
| `titleLarge`  | 24        | `w600`           | `darkBlue`  | `:25-29` |
| `bodyLarge`   | 16        | (regular ≈400)   | `grey`      | `:30`    |
| `bodyMedium`  | 14        | (regular ≈400)   | `grey`      | `:31`    |
| `elevatedButton`| 16     | `bold` (700)     | `white` on `primaryBlue` | `:43-44` |

### 2.3 Ad-hoc text styles by frequency of use

(Extracted across the doctor screens — these are the values you'll
encounter repeatedly.)

| Size | Weight | Common color  | Example use                                                 |
|------|--------|---------------|-------------------------------------------------------------|
| 38   | bold + `letterSpacing:6` | white | Splash "NABDA" title (`splash_screen.dart:464`) |
| 32   | bold   | darkBlue      | Theme `displayLarge`                                        |
| 28   | bold   | white         | Live HR/SpO₂/Battery values (`patient_vitals_screen.dart:393, 429, 477`) |
| 26   | w800   | colored       | StatCard value (`stat_card.dart:142-146`)                   |
| 24   | w600   | darkBlue      | Theme `titleLarge`                                          |
| 22   | bold   | darkBlue / white | Page section title (logout dialog), profile name      |
| 22   | bold   | darkBlue      | Section header (`profile_screen.dart:687-690`)              |
| 22   | w800   | darkBlue      | Appointments app-bar title (`doctor_appointments_screen.dart:138-141`) |
| 20   | bold   | darkBlue      | Patient detail name (`patient_detail_screen.dart:364`); Empty state title (`empty_state_view.dart:57-58`) |
| 20   | bold   | darkBlue      | Edit profile sheet title (`profile_screen.dart:300-304`)    |
| 18   | bold   | darkBlue      | Section titles ("Vitals", "Live Vitals", "Health Trends", patient info card title, "Summary for today") |
| 18   | w800   | darkBlue + `letterSpacing:0.5` | Appointments grouped section header (`doctor_appointments_screen.dart:399-407`) |
| 18   | bold   | white         | CustomButton text (`custom_button.dart:69-73`) `letterSpacing:0.5` |
| 16   | bold   | colored / white | Appointment patient name; profile section title; profile save button |
| 16   | bold   | darkBlue      | Edit field labels                                           |
| 16   | bold   | darkBlue/white| Profile edit gradient button (`profile_screen.dart:776-780`)|
| 16   | w700   | darkBlue      | Chat app-bar name (`patient_chat_screen.dart:319-321`)      |
| 15   | bold   | darkBlue      | PatientCard name (`patient_card.dart:109-112`)              |
| 15   | regular| (depends)     | Chat bubble content + `height: 1.4` (`patient_chat_screen.dart:644-647`); Profile info tile value `w600` (`profile_screen.dart:973-975`); Auth field labels |
| 15   | w600   | typeColor / grey | Auth dialog buttons (`auth_screen.dart:360-364`)        |
| 14   | bold   | darkBlue      | AlertCard title (`alert_card.dart:50-54`)                   |
| 14   | w600   | darkBlue      | Appointment date/time row (`doctor_appointments_screen.dart:556-560, 582-587`); Notif title bold-when-unread else `w500` (`notifications_screen.dart:441-450`) |
| 14   | regular| grey          | Theme `bodyMedium`; Patient detail email (`:373`); Notif body (`:478`) |
| 13   | w600   | darkBlue / colored | Banner text (`patient_vitals_screen.dart:243-244`); Connection states |
| 13   | bold   | darkBlue      | Vital card title in chart (`patient_vitals_screen.dart:703-706`) |
| 13   | regular| grey          | Notif body / patient bio chip value (when value font 13 / w700) |
| 12   | w600   | colored       | Chat tile status/last-seen pill (`doctor_dashboard_screen.dart:1407-1413`); SaveChanges button on auth (`:425`); Chat status pill text |
| 12   | regular| grey          | Header date pill, profile labels, chip captions, divider date label |
| 12   | bold   | white         | Stat card label (`stat_card.dart:151-156`)                  |
| 11   | bold   | white         | Appointment status badge (`doctor_appointments_screen.dart:524-528`); Patient info chip label (`patient_detail_screen.dart:524-528`) |
| 11   | w500   | grey/typeColor| Chat bubble timestamp (`patient_chat_screen.dart:660-663`); patient bio chip label (`:524-528`) |
| 11   | regular| grey          | Stat chip values (`patient_detail_screen.dart`)              |
| 10   | regular| grey          | Chart axis labels (`patient_vitals_screen.dart:781, 791`)   |
| 10   | w600   | typeColor / grey | Status pill in chat tile (`doctor_dashboard_screen.dart:1409-1413`); Fit/Scroll toggle (`patient_vitals_screen.dart:557-561`); chart "Avg / Range" subtitle (`patient_vitals_screen.dart:1016-1019`) |
| 9    | italic | colored × 0.5 | Chart stat subtitle (`patient_vitals_screen.dart:1016-1019`) |

### 2.4 Letter spacing

| Value | Use | Source |
|-------|-----|--------|
| 6     | "NABDA" splash | `splash_screen.dart:464` |
| 1.5   | "Your Health, Your Pulse" tagline | `splash_screen.dart:476` |
| 0.5   | CustomButton text | `custom_button.dart:72` |
| 0.5   | Appointments grouped section header | `doctor_appointments_screen.dart:405` |

### 2.5 Line height

Only one explicit `height` value appears: chat bubble content
`height: 1.4` (`patient_chat_screen.dart:646`). For all other text,
Flutter uses font defaults (`~1.2–1.3`). Web should set
`leading-relaxed` / `leading-normal` per element to match.

For descriptive body paragraphs (server-down / no-internet text):
`height: 1.5` (`no_internet_view.dart:112`, `server_down_view.dart:184`).

For Auth dialog description: `height: 1.4`
(`auth_screen.dart:294`, `logout_dialog.dart:108`).

### 2.6 Text-scaler clamp (mobile-specific) ⚠️

Mobile clamps OS-level text scale to `[1.0, 1.3]`
(`lib/main.dart:73-79`). On the web, respect the browser default but
consider clamping body sizes with `clamp()` so the layout stays sane at
200% zoom.

### 2.7 Form-field typography

| Element                            | Style                                            | Source |
|------------------------------------|---------------------------------------------------|--------|
| Form field label                   | grey                                              | `auth_screen.dart:921-923`, `profile_screen.dart:491` |
| Form field hint                    | grey, 14 px (default)                             | implicit |
| Form field text                    | 16 px black87 (default)                           | implicit (DOB picker `:998-1000`) |
| Form field error                   | error red, 1–1.5 px border                        | `auth_screen.dart:940-946` |

### 2.8 Headings / labels in widgets

- `SectionTitle` (`lib/widgets/reusable/section_title.dart:24-29`):
  `titleLarge` (24 px) with `fontWeight: w800` and `color: darkBlue`.
- `StatusCard` title: `bodyMedium` (14 px) + `color: grey`; value =
  `titleLarge` (24 px) + bold + accentColor (`status_card.dart:156-173`).
- `LogoutDialog` title: 22 px bold darkBlue (`logout_dialog.dart:96-101`).
  Description: 15 px grey + `height: 1.4` (`:104-111`).

### 2.9 Button text

- **CustomButton**: 18 px / bold / letterSpacing 0.5 / white.
- **ElevatedButtonTheme** (default): 16 px / bold
  (`app_theme.dart:43-44`).
- **TextButton** (e.g. "Cancel"): inherits color (`primaryBlue` /
  `darkBlue`); commonly 15 px / `w600`.

### 2.10 Suggested web type ramp (Tailwind)

```ts
fontSize: {
  '2xs': ['10px', { lineHeight: '1.2' }],
  'xs':  ['11px', { lineHeight: '1.3' }],
  'sm':  ['12px', { lineHeight: '1.3' }],
  'base':['14px', { lineHeight: '1.4' }],
  'md':  ['15px', { lineHeight: '1.4' }],
  'lg':  ['16px', { lineHeight: '1.4' }],
  'xl':  ['18px', { lineHeight: '1.3' }],
  '2xl': ['20px', { lineHeight: '1.25' }],
  '3xl': ['22px', { lineHeight: '1.25' }],
  '4xl': ['24px', { lineHeight: '1.2' }],
  '5xl': ['26px', { lineHeight: '1.1' }],
  '6xl': ['28px', { lineHeight: '1.1' }],
  '7xl': ['32px', { lineHeight: '1.1' }],
  '8xl': ['38px', { lineHeight: '1.1', letterSpacing: '0.4em' }], // splash
},
fontWeight: { normal: 400, medium: 500, semibold: 600, bold: 700, extrabold: 800 },
```

---

## 3. Layout system

### 3.1 Spacing tokens (`lib/utils/constants.dart:56`)

| Token       | px |
|-------------|----|
| `paddingS`  | 8  |
| `paddingM`  | 16 |
| `paddingL`  | 24 |
| `paddingXL` | 32 |

Used throughout. Recommended Tailwind theme:

```ts
spacing: {
  'xs': '4px',   's': '8px',   'sm': '12px',  'm':  '16px',
  'lg': '24px',  'xl': '32px', '2xl': '40px',
}
```

### 3.2 Border radius tokens (`constants.dart:56`)

| Token       | px |
|-------------|----|
| `radiusS`   | 8  |
| `radiusM`   | 16 |
| `radiusL`   | 24 |
| `radiusXL`  | 30 |

Other radii encountered in code (not tokenized but recurring):
- 10 (badge / small pill)
- 12 (small card, chips, list-item-card)
- 14 (medium card, button)
- 20 (large card, hero appointment card, message bubble)
- 26 (Google button pill)
- 28 (gradient assessment header bottom corners)

### 3.3 Page-level spacing

| Surface                           | Padding                                 | Source            |
|-----------------------------------|------------------------------------------|-------------------|
| Auth screen padding               | 24 (paddingL) on all sides, top 0 below SafeArea | `auth_screen.dart:469-474` |
| Doctor dashboard content body     | 24 (paddingL)                            | `doctor_dashboard_screen.dart:838` |
| Patient detail content            | 24                                       | `patient_detail_screen.dart:139` |
| Doctor appointments list          | 24                                       | `doctor_appointments_screen.dart:236, 310, 373` |
| Profile content                   | 24                                       | `profile_screen.dart:736` |
| Notifications list                | 16 (paddingM)                            | `notifications_screen.dart:345` |
| Vitals screen                     | 24                                       | `patient_vitals_screen.dart:186` |
| Chat list (messages)              | left 16, right 16, bottom 16, top 8      | `patient_chat_screen.dart:434` |
| Chat input row                    | 16 (h) / 8 (top) / 16 (bottom)           | `patient_chat_screen.dart:456` |
| ListSkeleton                      | 16 h / 16 v                              | `list_skeleton.dart:23-27` |
| AssignPatientSheet header         | 24 h / 20 top / 0 bottom                 | `assign_patient_sheet.dart:293` |
| Empty state                       | 32 all                                   | `empty_state_view.dart:27` |
| Logout dialog                     | 24 all                                   | `logout_dialog.dart:64` |
| Forgot password dialog            | 24 all                                   | `auth_screen.dart:247` |

### 3.4 Spacing between items (gaps)

- Card-to-card (vertical) in patient list: 16 (paddingM) `:1561`
- Card-to-card (vertical) in appointments: 24 (paddingL) `:436`
- Card-to-card (vertical) in chats list: 8 (paddingS) `:1260`
- Card-to-card (vertical) in notifications: 8 (paddingS) `:365`
- Stat-grid spacing: 16 (paddingM) both axes `:847-848`
- Dashboard stat grid `childAspectRatio`: 1.5 `:849`
- Grid 2-col vitals (patient detail): 16 spacing both axes, ratio 1.5 `:205-208`
- Vitals live-card row spacing: 12 between cards
- AI report card-to-card gap: 16
- Section header → first item gap: 16 (paddingM)
- Default `SizedBox(height: AppDimensions.paddingS / M / L)` between text and next block

### 3.5 Component sizes

| Component               | Size                                  | Source |
|-------------------------|---------------------------------------|--------|
| App bar (default)       | 56                                    | Flutter default |
| Patient chat app bar    | 70 (`toolbarHeight`)                  | `patient_chat_screen.dart:266` |
| SliverAppBar expanded (dashboard) | 170                          | `doctor_dashboard_screen.dart:666` |
| SliverAppBar expanded (profile)   | 280                          | `profile_screen.dart:552` |
| AppLogo (splash)        | 120 px (inside 200×200 pulse ring)    | `splash_screen.dart:439` |
| AppLogo (auth)          | 80 px                                 | `auth_screen.dart:480` |
| AppLogo (default)       | 150 px                                | `app_logo.dart:14` |
| Profile avatar (hero)   | 50 px radius                          | `profile_screen.dart:640` |
| PatientCard avatar      | 26 px radius                          | `patient_card.dart:77, 83` |
| ChatTile avatar         | 26 px radius                          | `doctor_dashboard_screen.dart:1311-1315` |
| Chat app bar avatar     | 20 px radius                          | `patient_chat_screen.dart:289-294` |
| Message-bubble side avatar | 12 px radius (`iconSize:14`)       | `:597-601` |
| Status dot on avatar    | 14 px (border 2.5)                    | `:299-305`, `patient_card.dart:88-96` |
| Online dot (small)      | 8 px                                  | `notifications_screen.dart:458-470` |
| Stat icon container     | 8 px padding (~40 outer), bg color × 10–16% | `stat_card.dart:108-122` |
| Appointment status icon orb | 10 px padding inside 40 px circle | `doctor_appointments_screen.dart:462-484` |
| Notification icon tile  | 44×44, radius 12                      | `notifications_screen.dart:406-417` |
| Bottom nav container    | 16 margin, radius 30, 8 padding       | `custom_bottom_nav.dart:21-34` |
| CustomBottomNav item (selected) | 12 h pad, 12 v pad           | `:50-53` |
| CustomBottomNav badge   | 16 min size, 10 px radius, 9 pt text  | `:85-105` |
| Chat send button        | 52×52 circle                          | `patient_chat_screen.dart:505-506` |
| Chat input              | rounded 30, internal `vertical:14 contentPadding` + 16 padding | `:494, 463` |
| Search field            | rounded 14, padding 16 h / 14 v       | `doctor_dashboard_screen.dart:1499-1506` |
| Pillpicker chip (Period)| h 14, v 6, radius 10                  | `patient_vitals_screen.dart:870-873` |
| CustomButton            | full width, vertical pad 18, radius 24| `custom_button.dart:50-54` |
| Profile edit button     | full width, pad 16, radius 14         | `profile_screen.dart:747-754` |
| Save button             | vertical pad 16, radius 14            | `profile_screen.dart:457-460` |
| Logout dialog buttons   | vertical pad 14, radius 12            | `logout_dialog.dart:122-129` |
| Forgot-password Send/Cancel buttons | vertical 14, radius 12    | `auth_screen.dart:349-355` |
| Assign-result "Assign" pill | h 14, v 8, radius 10              | `assign_patient_sheet.dart:741-747` |
| Tab pill (segmented)    | h 12, v 10, radius 10                 | `auth_screen.dart:879-882`, `:519-525` |
| Date separator chip     | h 12, v 4, radius 12                  | `patient_chat_screen.dart:557-561` |
| Status badge (appointment) | h 10, v 6, radius 12               | `doctor_appointments_screen.dart:514-520` |
| Bio info chip (patient) | h 12, v 10, radius 12                 | `patient_detail_screen.dart:501-507` |

### 3.6 Mobile-specific patterns and web equivalents

| Mobile pattern                            | Web equivalent                                |
|-------------------------------------------|------------------------------------------------|
| `CustomBottomNavBar` (4-tab pill)         | Permanent left **sidebar** (≥1024 px) or top tabs (<1024) |
| `SliverAppBar` collapsing gradient header | Sticky `<header>` with gradient + scroll-trigger collapse via CSS sticky |
| FAB (`schedule_appointment`, `send_message`, "Assign Patient") | Inline buttons in a sticky action bar OR header CTAs |
| `Dismissible` swipe-to-delete patient card | Explicit delete icon already present in `PatientCard.onDeleteTap` |
| `showModalBottomSheet` (AssignPatientSheet, ImagePicker, EditProfile) | Centered modal dialog (max-w 520, radius 16, scroll within) |
| Heads-up local notification (foreground)  | Top-anchored toast (sonner / radix toast) |
| `BackdropFilter` (none used)              | n/a |
| Heart-beat pulse on logo (animated)       | CSS `@keyframes` scaling + opacity on SVG path |
| Foreground / UDP listener                 | None — drop entirely |
| `Dialog` (logout, forgot-password)        | Radix Dialog / Headless UI Dialog |
| Connectivity gates (NoInternet/ServerDown) | Same screens on web; use `navigator.onLine` + heartbeat fetch |
| `DefaultTabController` (Appointments 4 tabs) | URL-driven tabs with `?tab=` query / `<Tabs>` component |
| `RefreshIndicator` (pull-to-refresh)      | Manual "Refresh" button in header / icon |
| `PageView` swipe (dashboard tabs)         | Route-based nav (no swipe); leave keyboard-arrow nav optional |
| `BouncingScrollPhysics`                   | `overscroll-behavior: contain` |
| `ImagePicker` + `ImageCropper` (camera/gallery + circular crop) | `<input type="file">` + `react-easy-crop` |
| Date pickers (`showDatePicker`, `showTimePicker`) | `<input type="date">` + `<input type="time">` or a date-picker library matching mobile theme |
| `RawDatagramSocket` UDP listener          | n/a (mobile only) |

### 3.7 Background "decoration" pattern (`DecoratedBackground`)

Used on Doctor Dashboard, Patients tab, Patient Detail, Notifications,
Appointments, Vitals, Profile, Chat list. Implementation:

- White base (`AppColors.white`).
- Top-right circle 200×200 at `(-80, -60)` filled `primaryBlue × 4%`.
- Bottom-left circle 250×250 at `(-100, -80)` filled `primaryBlue × 4%`.
- Accent circle 100×100 at `(150, -40)` filled `accentTeal × 3%`.

Source: `lib/widgets/reusable/decorated_background.dart`.

Web rendering:

```css
.decorated-bg {
  position: relative;
  background: #FFFFFF;
  isolation: isolate;
}
.decorated-bg::before,
.decorated-bg::after {
  content: '';
  position: absolute;
  border-radius: 9999px;
  pointer-events: none;
  z-index: 0;
}
.decorated-bg::before { /* top-right */
  width: 200px; height: 200px;
  top: -80px; right: -60px;
  background: rgba(64, 123, 255, 0.04);
}
.decorated-bg::after { /* bottom-left */
  width: 250px; height: 250px;
  bottom: -100px; left: -80px;
  background: rgba(64, 123, 255, 0.04);
}
.decorated-bg > .accent {
  position: absolute; top: 150px; left: -40px;
  width: 100px; height: 100px; border-radius: 9999px;
  background: rgba(0, 191, 165, 0.03);
}
```

### 3.8 Patient chat custom background

`patient_chat_screen.dart:343-382` adds three additional decorative
circles on top of a `#F4F7FA` base. Replicate with positioned `<div>`s.

### 3.9 Page transitions

`AppPageRoute` (`lib/routes/app_page_route.dart`):
- Forward: fade `0→1` (350 ms) + slide from `Offset(0.05, 0)` → `Offset.zero`,
  curve `easeOutCubic`.
- Reverse: 300 ms, `easeIn`.
- `AppScaleRoute` (modals): fade + scale `0.95 → 1.0`, 300 ms.

Web equivalent: framer-motion AnimatePresence with
`initial={{ opacity: 0, x: 16 }} animate={{ opacity: 1, x: 0 }}`.

### 3.10 Common animation durations

| Animation                | Duration | Curve                    | Source |
|--------------------------|----------|--------------------------|--------|
| Page transition fwd      | 350 ms   | easeOutCubic             | `app_page_route.dart:12` |
| Page transition rev      | 300 ms   | easeIn                   | `:13` |
| `FadeSlideTransition`    | 500 ms (default), `easeOutCubic`, slide `(0, 0.1)` → 0 | `fade_slide_transition.dart:16-20` |
| `AnimatedListItem`       | 400 ms, staggerDelay 80 ms × index, slide `(0, 0.15)` → 0 | `animated_list_item.dart:19-23` |
| `ScaleOnTap`             | 100 ms, scale 1 → 0.95, easeInOut | `scale_on_tap.dart:17-18` |
| AnimatedToast slide      | 600 ms in (`elasticOut`), 400 ms out (`easeIn`) | `animated_toast.dart:32-49` |
| Toast auto-dismiss       | 4000 ms | (timer) | `notification_service.dart:73-75` |
| Heartbeat pulse (splash) | 1200 ms loop, 5-stage tween (`splash_screen.dart:60-79`) | |
| ECG draw (splash)        | 1800 ms loop, easeInOut | `:81-89` |
| Pulse rings (splash, server-down) | 1800 ms / 3000 ms loops | `:111-122`, `server_down_view.dart:41-45` |
| ServerDown pulse icon    | 2000 ms reverse loop, scale 1 → 1.2 | `:32-39` |
| NoInternet pulse icon    | 2000 ms reverse loop, scale 1 → 1.1 | `no_internet_view.dart:18-26` |
| StatCard background      | 3000 ms loop sin   | `stat_card.dart:36-39` |
| StatusCard pulse glow    | 2500 ms loop sin   | `status_card.dart:36-39` |
| VitalCard primary        | 1800 ms loop       | `vital_card.dart:43-45` |
| VitalCard secondary      | 3000 ms loop       | `:46-48` |
| Chart appear             | 600 ms             | `patient_vitals_screen.dart:809, 830` |
| Page scroll-to-bottom    | 300 ms, easeOut    | `patient_chat_screen.dart:216-218` |
| Bottom-nav animated container | 300 ms easeOutCubic | `custom_bottom_nav.dart:48-49` |

### 3.11 Material Design baseline

Tap targets follow Material defaults (48×48 hit area minimum). Web
should respect `min-w-[44px] min-h-[44px]` per WCAG.

---

## 4. Localization & RTL

- Languages: English (`en`), Arabic (`ar`). Default `en`.
- `main.dart:55-70` clamps to `supportedLocales` (`en`, `ar`) and falls
  back to first locale (English).
- AI report history forces `Directionality(textDirection: TextDirection.rtl)`
  even when device locale is English
  (`report_history_screen.dart:47-49`). On web this corresponds to
  `<section dir="rtl">` for the AI report area.
- Cairo font is applied to Arabic strings inline (e.g. "عرض تقارير التقييم"
  in `patient_detail_screen.dart:268-273`).
- Mobile uses Flutter's auto RTL mirroring. Web equivalent: set
  `dir="rtl"` on `<html>` when `lang=ar`; use CSS logical properties.

---

## 5. Light-mode only

`AppTheme.darkTheme` was removed (comment in `app_theme.dart:50`). All
surfaces assume a light theme. The web app should not implement a dark
mode in v1.

---

## 6. Iconography (complete inventory)

All icons are Material Icons referenced inline via `Icons.<name>`. The
"rounded" variant is preferred (suffix `_rounded`). Web should use
`Material Symbols Rounded` from Google Fonts, or `@mui/icons-material`.

### 6.1 By surface

**Doctor dashboard:**
- `dashboard_outlined`, `dashboard`, `chat_outlined`, `chat`,
  `people_outline`, `people`, `person_outline`, `person`,
  `notifications_outlined`, `calendar_month_outlined`,
  `warning_amber_rounded`, `message`, `calendar_today`,
  `event_busy`, `person_add_rounded`, `person_remove_rounded`,
  `search`, `clear`, `medical_services` (avatar fallback).

**Patient card / detail:**
- `favorite` (HR), `water_drop` (SpO₂), `battery_charging_full`,
  `calendar_today`, `access_time`, `show_chart`, `analytics_outlined`,
  `person_outline`, `calendar_today_outlined`, `height`, `monitor_weight_outlined`,
  `delete_rounded`, `person_remove_rounded`, `check_circle`, `error_outline`.

**Vitals screen:**
- `favorite`, `water_drop`, `battery_full` / `battery_3_bar` /
  `battery_1_bar` / `battery_unknown`, `cloud_off`, `sync`, `wifi_off`,
  `warning_amber`, `show_chart`, `swipe`, `fit_screen`, `watch_off`.

**Chat:**
- `send_rounded`, `remove_red_eye_rounded` (read tick),
  `done_all_rounded` (delivered), `check_rounded` (sent),
  `mark_chat_unread_rounded` (empty state).

**Appointments:**
- `today_rounded`, `wb_sunny_rounded`, `date_range_rounded`,
  `event_note_rounded`, `history_rounded`, `event_available_rounded`,
  `event_busy_rounded`, `event_available`, `cancel`, `check_circle`,
  `calendar_month`, `access_time_filled`, `close`, `check`.

**Notifications:**
- `chat_bubble_rounded`, `calendar_today_rounded`, `check_circle_rounded`,
  `cancel_rounded`, `task_alt_rounded`, `notifications_rounded`,
  `delete_outline_rounded`, `delete_sweep_rounded`,
  `notifications_off_rounded`.

**Profile / settings:**
- `person`, `email_outlined`, `phone_outlined`, `wc_rounded`,
  `cake_outlined`, `height`, `monitor_weight_outlined`, `settings`,
  `logout`, `logout_rounded`, `chevron_right`, `edit`,
  `camera_alt`, `photo_library`, `delete`.

**Auth screen:**
- `email`, `lock`, `person`, `phone`, `calendar_today`, `wc_rounded`,
  `visibility`, `visibility_off`, `email_outlined`, `lock_reset_rounded`,
  `g_mobiledata` (Google fallback).

**Global / shared:**
- `error_rounded`, `warning_rounded`, `check_circle`,
  `help_outline_rounded` (StatusCard).
- `error_outline_rounded`, `chat_bubble_outline_rounded`,
  `group_off_rounded`, `search_off_rounded`, `person_search_rounded`
  (EmptyStateView usages).
- `wifi_off_rounded` (NoInternet), `dns_rounded` (ServerDown).
- `refresh_rounded` (EmptyStateView retry).

### 6.2 Icon sizes used

| Use                                | Size |
|------------------------------------|------|
| Bottom-nav active icon             | 24   |
| Bottom-nav idle icon               | 22   |
| Stat card icon                     | 22 (in 8 padding bg) and 70 background ghost (`stat_card.dart:96`) |
| App-bar icon button                | 24 (default) |
| Patient card status dot icon       | n/a (no icon, just dot) |
| Chat send button icon              | 22 |
| Forgot-password dialog icon        | 40 inside 16-pad bg |
| Logout dialog icon                 | 40 |
| EmptyState icon                    | 64 (inside 28+24 pad outer ring) |
| NoInternet icon                    | 80 |
| ServerDown icon                    | 64 |
| Period chip / segmented icon       | 18 |
| Bio chip icon                      | 16 |
| Notification icon                  | 22 inside 44 box |
| Search prefix                      | 24 (default), `primaryBlue` |
| Vital live card icon               | 28 |
| Status pill icon (chat tile)       | n/a (text only) |
| Date separator                     | n/a |
| Avatar fallback icon               | radius × 0.9 (auto) (`user_avatar.dart:163`) |
| AlertCard icon                     | 24 inside 10 pad bg |
| Heart-rate vital card icon (subtle)| 18 inside 6 pad bg |
| Logout-in-app-bar icon             | 22 inside 10 pad bg |
| Edit field prefix                  | 20 |

---

## 7. Web translation cheat-sheet

| Flutter                              | Tailwind / web                                       |
|--------------------------------------|------------------------------------------------------|
| `BorderRadius.circular(16)`          | `rounded-2xl` (defines via tokens; 16=2xl)           |
| `Padding(EdgeInsets.all(AppDimensions.paddingL))` | `p-6` (24px)                            |
| `BoxShadow(blurRadius:20, offset:Offset(0,8), color:primaryBlue × 8%)` | `shadow-[0_8px_20px_rgba(64,123,255,0.08)]` |
| `LinearGradient(begin:topLeft, end:bottomRight, colors:[#407BFF,#00B4D8])` | `bg-gradient-to-br from-[#407BFF] to-[#00B4D8]` |
| `withValues(alpha: 0.1)`             | Tailwind opacity modifiers `bg-primary/10`           |
| `BoxShape.circle`                    | `rounded-full`                                       |
| `Positioned(top:-80, right:-60, …)`  | `absolute -top-20 -right-15`                          |
| `Stack`                              | `relative` with absolutely-positioned children       |
| `CircleAvatar`                       | `<div class="rounded-full overflow-hidden ...">`     |
| `SafeArea`                           | env(safe-area-inset-…) on mobile web; otherwise n/a  |
| `RefreshIndicator`                   | Explicit button or `pull-to-refresh` lib (rarely worth it on desktop) |
| Material `IconButton`                | `<button class="p-2 rounded-full hover:bg-grey/10">` |
| `TextField` with `prefixIcon`        | `<input>` + absolutely-positioned `<svg>` icon       |

---

## 8. Open visual decisions (web only)

Things the mobile app doesn't establish, that the web app should:

- **Hover states**: mobile has no hover. Web should add subtle hover
  bg (e.g. `hover:bg-primary/5`) on every clickable card / row.
- **Focus rings**: mobile has none. Web must add visible focus rings for
  a11y (`focus-visible:ring-2 ring-primary/40 ring-offset-2`).
- **Cursor**: `cursor: pointer` for every tappable surface.
- **Sidebar width**: pick 240–280 px (collapsed 72 px).
- **Topbar height**: 64 px (matches Material).
- **Container max-widths**: dashboards full bleed; reading content
  `max-w-screen-lg` (1024 px) centered.
- **Skeleton shimmer**: web `keyframes` translating a linear-gradient
  across a `bg-grey-200` element matches the mobile `shimmer` package.

---

## 9. Screen blueprints (doctor-only, exhaustive)

Each screen below is described in enough detail to recreate it without
reading the Flutter source.

---

### 9.1 Splash screen

- **Source:** `lib/screens/splash/splash_screen.dart`.
- **Doctor relevance:** entry gate; doctors see this on every cold
  start (~2 sec).
- **Background:** full-screen `primaryGradient` (#407BFF → #00B4D8,
  TopLeft → BottomRight) with two large translucent white circles
  (300×300 at top-left, 250×250 at bottom-right; each ~6–8% alpha,
  vertically drifting ±10 px via a 3 s sin loop).
- **ECG waveform overlay**: full-bleed `CustomPaint` scrolling PQRST
  line, stroke `white × 6%`, 1.5 px width, looping 1.8 s.
- **Center column:**
  - **Pulse rings**: two layered circles (168×168), 2-px white border,
    scale 1 → 1.8 over 1.8 s (one offset by 0.5 phase).
  - **Logo wrapper**: 200×200 stack, padded 24 px white/20%-bg circle
    around an `AppLogo` (120 px ECG logo). Scaled by heartbeat
    animation (5-stage lub-dub-pause tween, 1.2 s loop, peaks 1.12 then
    1.06).
  - 24 gap.
  - **"NABDA"** title 38 / bold / white / `letterSpacing: 6`.
  - 8 gap.
  - Tagline **"Your Health, Your Pulse"** — `bodyLarge` (16) / white/70 /
    light (300) / letterSpacing 1.5. Fades in 1 s after 400 ms delay.
- **Gates (during the 2 s delay):**
  - **No internet** → swap to `NoInternetView`.
  - **Server unreachable** → swap to `ServerDownView` with 5-s polling.
- **Loading state:** the animation itself is the loading state — no
  spinner.

---

### 9.2 Login / Register (`/auth`)

- **Source:** `lib/screens/auth/auth_screen.dart`.
- **Doctor relevance:** primary entry for already-registered users; the
  "Doctor" role can self-register here.
- **Background:** plain `white` (no `DecoratedBackground`).
- **SafeArea padding:** 24 horizontal, 24 top.
- **Layout (top → bottom):**
  1. 20 spacer.
  2. **AppLogo** 80 px (fade-slide entrance, delay 100 ms).
  3. 16 spacer.
  4. Subtitle "Access your NABDA account" — `titleLarge` (24) bold,
     centered (delay 200 ms).
  5. 24 spacer.
  6. **Tab bar** "Login / Create Account" — labelColor primaryBlue,
     unselected grey, indicator primaryBlue (delay 300 ms).
  7. 24 spacer.
  8. Expanded **TabBarView**:
     - **Login form** (Form with `_loginFormKey`):
       - Field: Email — prefix icon `email`, value validator.
       - 16 spacer.
       - Field: Password — prefix `lock`, suffix `visibility(_off)`,
         validator (≥ 8 chars).
       - 8 spacer.
       - Right-aligned `TextButton` "Forgot password?" → opens
         forgot-password dialog.
       - 16 spacer.
       - `CustomButton` "Login" (gradient pill, 18 bold).
       - 24 spacer.
       - **Divider** "OR" (`Expanded(Divider)` 16-gap text in grey).
       - 16 spacer.
       - **Google button** pill: width full, height 52, bg `#F2F2F2`,
         radius 26. Centered Google "G" image 24×24 + 12 gap + label
         "Sign in with Google" 16 w500 `#1F1F1F` Roboto.
     - **Register form** (Form with `_registerFormKey`):
       - Role segmented control (Patient / Doctor) — bg `#F5F7FA`,
         radius 12, 4 padding; selected pill: white bg, shadow.
       - 16 spacer.
       - Fields, each 16 spacer apart:
         - Full Name (prefix `person`).
         - Phone (prefix `phone`, `TextInputType.phone`).
         - Date of Birth (InputDecorator + `showDatePicker`).
         - Gender (DropdownButtonFormField with Male/Female).
         - Patient-only: Height + Weight in a Row.
         - Email.
         - Password (with visibility toggle, ≥ 8 chars).
         - Confirm Password.
       - 24 spacer.
       - `CustomButton` "Create Account".
- **Forms:**
  - Field bg `#F5F7FA`, no border idle, `primaryBlue` 1.5-px focused,
    `error` 1-px error / 1.5 focused-error. Prefix icon `primaryBlue`.
  - `autovalidateMode: onUserInteraction`.
- **Error display:** validator strings show inline below each field;
  global API errors surface as `AnimatedToast` (error red).
- **Loading state:** when `_isLoading`, `CustomButton` shows a white
  spinner instead of text; the Google pill becomes non-tappable (the
  parent handles that via `_isLoading ? null : _handleGoogleSignIn`).
- **Empty state:** n/a.

---

### 9.3 Forgot Password dialog

- **Source:** `auth_screen.dart:235-439`.
- **Description:** Centered dialog 20-radius elevation-16. Content
  padding 24. Icon container 16-padding gradient
  (`primaryBlue × 15% → 5%`) circle with `lock_reset_rounded` 40
  primaryBlue. Title "Reset Password" 22 bold darkBlue. Description 14
  grey `height:1.4`. Email input (same field style as auth, with prefix
  icon container `primaryBlue × 10%`). Buttons row:
  - Cancel: OutlinedButton `grey × 30%` border, label 15 w600 darkBlue.
  - Send Reset Link: gradient ElevatedButton, 15 w600 white.
- **Validation:** Send button rejects empty / non-`@` emails with toast
  "Please enter a valid email".

---

### 9.4 Doctor Dashboard (`/doctor_dashboard`)

- **Source:** `lib/screens/doctor/doctor_dashboard_screen.dart`.
- **Top-level structure:** PageView of 4 pages controlled by
  `CustomBottomNavBar`:
  1. Dashboard (`_buildDashboardContent`).
  2. Chats (`_buildChatsContent`).
  3. My Patients (`_buildPatientsContent`).
  4. Profile (`ProfileScreen` — see §9.10).
- **Page background:** `AppColors.background` (#F8FAFC).
- **Bottom nav:** floating pill, 4 items (Dashboard, Chats, My Patients,
  Profile). Chats badge sums all `unreadCount`.

#### 9.4.1 Dashboard tab

- **SliverAppBar** (170 expanded, sticky):
  - `primaryGradient` filling the area.
  - Two oversized translucent circles (white × 8%).
  - SafeArea padded 24, bottom-left aligned row:
    - White-bordered (3-px) wrapper around `UserAvatar` 26 (fallback
      `medical_services`).
    - 16 gap. Column: "Hello" 14 white/90 + "Dr. {fullName}" 22 bold
      white + date pill ("Wed, Apr 1") 12 w500 white in 8/3-padded
      white/15 radius-12.
    - Notification icon button: `white × 15%` radius-12 with 12×12 red
      dot when unread > 0.
    - 8 gap. Calendar icon button (same style).
- **Body** (24 padding):
  - 2×2 grid of StatCards (ratio 1.5, 16 gap):
    1. Total patients (primaryBlue, `people`).
    2. Need attention (orange, `warning_amber_rounded`).
    3. Pending messages (accentTeal, `message`).
    4. Today's appointments (purple, `calendar_today`).
  - 16 spacer.
  - Single full-width StatCard "Missed appointments" (error red,
    `event_busy`).
  - 24 spacer.
  - Conditional `AlertCard` when `criticalCount > 0` (FadeSlide delay
    400). Title "Critical Alert", message "{n} patient(s) need
    immediate attention", button "View".
  - 24 spacer.
  - Section row: `SectionTitle` "Recent Patients" + TextButton "See
    All" (w600 primaryBlue).
  - 8 spacer.
  - **Patient list states:**
    - `_isLoadingPatients` → centered 32-padding `CircularProgressIndicator`.
    - `_patientsError != null` → centered column (icon `error_outline`
      48 grey, error text, "Retry" TextButton).
    - `_patients.isEmpty` → centered column (`people_outline` 48 in
      primaryBlue/30, "No patients assigned yet." grey).
    - Else → 3 `PatientCard`s.
- **Pull-to-refresh:** `RefreshIndicator` (color primaryBlue) that
  re-fetches patients, appointments, chats.

#### 9.4.2 Chats tab

- **Header:** AppBar (white, elevation 0) with title "Chats" 18 bold
  darkBlue.
- **Body:** `DecoratedBackground`.
- **Loading state:** `ListSkeleton(itemCount: 8, hasAvatar: true)`.
- **Empty state:** `EmptyStateView` with `chat_bubble_outline_rounded`,
  title "No conversations yet", description "Start chatting from the
  Patients tab!", action "Refresh".
- **List:** `ListView.builder`, padding 16h / 8v.
- **Tile:** see COMPONENT_INVENTORY §B.3. On tap → open
  `/patient_chat`.
- **Pull-to-refresh:** swipe down → refresh + presence re-fetch.

#### 9.4.3 My Patients tab

- **Header:** AppBar (white, elevation 0) with title "My Patients" 18
  bold darkBlue.
- **FAB:** `FloatingActionButton.extended` "Assign Patient" — bg
  primaryBlue, icon `person_add_rounded`, white label, elevation 4.
  Opens `AssignPatientSheet`.
- **Body:** `DecoratedBackground` with:
  - Search field (white container radius 14, shadow
    `0 2 10 black × 5%`): `Icons.search` prefix, "Search patients"
    placeholder, `Icons.clear` suffix when text exists; padding 16h/14v.
  - Expanded list:
    - Loading → `ListSkeleton(6, true)`.
    - Error → `EmptyStateView` (`error_outline_rounded` "Failed to load
      patients" + Retry).
    - Empty after search → `EmptyStateView` (`search_off_rounded`).
    - Empty default → `EmptyStateView` (`group_off_rounded` "No
      patients assigned yet." + "Assign a new patient to start
      monitoring them").
    - Else → `ListView.builder` of `Dismissible` swipe-to-delete
      `PatientCard`s. Background swipe reveals red panel with
      `delete_rounded` 26 white + "Remove" label 12 w600. Extra 80-px
      SizedBox at the end for FAB spacing.

---

### 9.5 Patient Detail (`/patient_detail`)

- **Source:** `lib/screens/doctor/patient_detail_screen.dart`.
- **AppBar:** white bg, elevation 0, dark-blue back button. Title
  "Patient Details" `titleLarge` (24) bold darkBlue. Trailing
  `person_remove_rounded` icon button (red bg 8%) → confirmation
  dialog then remove API call.
- **Body:** `DecoratedBackground` + `SingleChildScrollView` padded 24.
  Children stacked vertically with `AppDimensions.paddingL` (24) gaps:
  1. **Patient info card** — white radius-16, padding 24:
     - 35-radius `UserAvatar` (bg primaryBlue, fg white).
     - 16 gap.
     - Column: name 20 bold darkBlue, email 14 grey, row "Last update:
       {value}" with `access_time` 14 grey + 12 text grey.
  2. **StatusCard** "Current Health Status" (uses backend
     `healthStatus`).
  3. **Vitals header row:** "Vitals" 18 bold darkBlue + "View Charts"
     pill (primaryBlue × 10% bg, radius 20, border × 30%,
     `show_chart` 16 primaryBlue + label 12 w600 primaryBlue) →
     navigates to `/patient_vitals`.
  4. **Vitals grid 2×2 (ratio 1.5, 16 spacing):** `VitalCard`s with
     `subtleMode: true`:
     - Heart Rate (`favorite`, Colors.redAccent).
     - Blood Oxygen (`water_drop`, Colors.lightBlue).
     - Battery Level (`battery_charging_full`, Colors.green).
     - Next Follow-up (`calendar_today`, primaryBlue, value "N/A").
  5. **"View AI reports" button** — full width 16 v-padding,
     primaryBlue bg, 14 radius. Icon `analytics_outlined` + label
     "عرض تقارير التقييم" (Cairo font, 16 bold). Navigates to
     `/report_history` with `isDoctorView: true`.
  6. **Patient bio section** — white card 16 radius, padding 24:
     - Title "patientInfo" 18 bold darkBlue.
     - 14 spacer.
     - 2×2 grid (10 spacing) of bio chips (gender, age, height,
       weight). Each chip: see COMPONENT_INVENTORY §B.8.
  7. 140 spacer for FABs.
- **FAB stack** (`Column(crossAxisAlignment: end)`):
  - "Schedule Appointment" (white pill, primaryBlue icon + label).
  - 16 spacer.
  - "Send Message" (primaryBlue pill, white icon + label).
- **Live vitals subscription:** `ChatService.vitalsUpdates` updates
  the cards when an event matches `patientId`.
- **Loading state:** `_loadingVitals=true` keeps vitals values as `--`.
- **Empty / error:** none — cards default to `--` when no data.

---

### 9.6 Patient Vitals / Charts (`/patient_vitals`)

- **Source:** `lib/screens/doctor/patient_vitals_screen.dart`.
- **AppBar:** white bg, title = patient name 18 bold darkBlue, back button.
- **Body:** `DecoratedBackground` + ListView padded 24:
  1. **Connection banner** when offline / load error / WS reconnecting.
  2. **Live vital cards row** — Heart Rate / SpO₂ / Battery (see
     COMPONENT_INVENTORY §B.10). Status label above with a small dot
     ("Active" green, "Last seen X ago" orange, "No Data" grey).
     If no data → grey card with `watch_off` icon and message "Wear
     your device to start live monitoring".
  3. 24 spacer.
  4. **Chart container** — see COMPONENT_INVENTORY §B.11. Title row,
     subtitle, metric toggles, period selector (24H/7D/30D), Fit/Scroll
     toggle, chart area (RangeArea band + Line + circle markers).
  5. 24 spacer.
  6. **Stats summary** when data exists — COMPONENT_INVENTORY §B.12.
  7. 80 spacer.
- **Refresh:** swipe down → `_loadData()`.
- **Loading state:** full-screen `CircularProgressIndicator` (primary).
- **Empty state:** "No readings in the last 24 hours" / "No data for
  this period" centered with `show_chart` 48 grey/40 + 14 grey text.
- **Error state:** `_loadError=true` triggers the connection banner;
  cards still show last known data when available.

---

### 9.7 Doctor Appointments (`/doctor_appointments`)

- **Source:** `lib/screens/doctor/doctor_appointments_screen.dart`.
- **AppBar:** white bg, title 22 w800 darkBlue. Dynamic title:
  - "Missed Appointments" when `initialIndex == 1`.
  - "Today's Appointments" when `todayOnly`.
  - else "Appointments" (24/22 w800).
- **Body:** `DecoratedBackground`.
- **Segmented TabBar** (COMPONENT_INVENTORY §B.26):
  - 24 h margin, 16 v margin, bg `lightGrey × 40%`, radius 30, 4 padding.
  - Inner TabBar pill indicator (white + radius 26 + shadow), 4 tabs
    height 48: Upcoming / Missed / Completed / Cancelled.
- **TabBarView body:**
  - **Loading:** `ListSkeleton(4, false)`.
  - **Error:** `EmptyStateView(error_outline_rounded, 'Error loading', desc, Retry)`.
  - **Upcoming tab** groups by relative day (Today / Tomorrow / Next Week
    / Following Week / Later). Each group header (COMPONENT_INVENTORY
    §B.5) precedes a sub-list of `_buildAppointmentCard`s.
  - **Missed tab** flat list, descending by date.
  - **Completed / Cancelled tabs** flat lists, descending by date.
  - **Empty per tab** → `EmptyStateView(event_busy_rounded / event_available_rounded, ...)`.
- **Appointment card:** COMPONENT_INVENTORY §B.4. Cancel/Complete
  actions only on `SCHEDULED` status.
- **Optimistic update:** changing status updates the row immediately;
  on failure re-fetch.

---

### 9.8 Patient Chat (`/patient_chat`)

- **Source:** `lib/screens/doctor/patient_chat_screen.dart`.
- **AppBar** (70 toolbar height, white, rounded bottom 24):
  - Avatar 20 with shadow + 14×14 status dot.
  - 14 gap.
  - Column: name 16 w700 darkBlue, status text 12 w500 (`accentTeal`
    online / `grey` offline / last-seen text).
- **Body** (`extendBodyBehindAppBar: true`):
  - Background base `#F4F7FA`.
  - Three decorative circles (`primaryBlue × 4%`, `accentTeal × 3%`,
    `primaryBlue × 2%`).
  - Column:
    - Top spacer = kToolbarHeight + safe-area inset.
    - **Messages list:**
      - Loading state → centered `CircularProgressIndicator(primaryBlue)`.
      - Empty state → centered column with 24-padding `primaryBlue × 5%`
        circle containing `mark_chat_unread_rounded` 64 primaryBlue × 50%.
        Title "No messages yet" 18 bold darkBlue + description "Send a
        message to start the conversation!" 14 grey × 80%.
      - Else → `ListView.builder` padded `(16,16,16,8)`:
        - Date separator before message if day differs (COMPONENT_INVENTORY §B.6).
        - Message bubble (COMPONENT_INVENTORY §B.7).
    - **Input row** (SafeArea + 16h + 8t + 16b padding):
      - Input: white radius-30, shadow `0 5 15 black × 5%`, border
        `lightGrey × 50%` 1 px, 16-padding-left + `TextField` (border
        none, isDense, contentPadding 14 v). Placeholder "Type a
        message…" 15 grey × 60%.
      - 12 gap.
      - 52×52 send button: `primaryGradient` circle, shadow
        `0 4 12 primaryBlue × 30%`, white `send_rounded` 22.
- **Behaviors:** optimistic message append, scroll-to-bottom 300 ms.
  Marks chat read on open, deletes chat-type notifications, polls
  presence every 15 s.

---

### 9.9 Notifications (`/notifications`)

- **Source:** `lib/screens/notifications/notifications_screen.dart`.
- **AppBar:** white, title "Notifications" bold darkBlue. Actions:
  - When unread: TextButton "Mark all" 13 px.
  - When list non-empty: IconButton `delete_sweep_rounded` error red.
- **Body:** `DecoratedBackground` + paginated `ListView`.
- **Loading:** `ListSkeleton(8, false, compact: true)`.
- **Empty:** `EmptyStateView(notifications_off_rounded, "No notifications", "When you receive alerts or messages, they will appear here.", "Refresh")`.
- **Pagination:** infinite scroll size 20 — last item is a 16-pad
  centered `CircularProgressIndicator(primary)` while loading.
- **Tile:** COMPONENT_INVENTORY §B.13.
- **Tap behavior:**
  - Mark as read (optimistic).
  - If `type == 'CHAT'` and `relatedId` present → navigate to
    `/doctor_chat` with that user.
  - If `type starts with 'APPOINTMENT'` → navigate to
    `/doctor_appointments`.
- **Delete:** instant local removal + background API delete.

---

### 9.10 Profile (`/profile` or 4th tab on dashboard)

- **Source:** `lib/screens/profile/profile_screen.dart`.
- **Sliver header** (280 expanded):
  - `primaryGradient` bg + two decorative white circles (8% alpha).
  - Top-right circular Logout button (white × 15% bg, `logout_rounded`
    22 white).
  - Centered column: 50-radius avatar with 3-px `white × 50%` border
    wrapper, `accentTeal` camera badge bottom-right (`camera_alt`
    16 white). Name 22 bold white, email 14 white/85, role pill 12 w600
    white in `white × 20%` rounded-20.
- **Body padded 24:**
  - **Edit Profile gradient button** — see COMPONENT_INVENTORY §B.21.
  - 24 spacer.
  - **Personal Information section** (COMPONENT_INVENTORY §B.17) with
    info tiles: Full Name, Email, Phone, Gender, Date of Birth.
  - 16 spacer.
  - **(Patient only) Health Information** — height + weight.
  - 16 spacer.
  - **Profile options list:** Settings (`settings`), Logout (`logout`).
- **Edit Profile bottom sheet** (mobile pattern, web → modal dialog):
  - Drag handle, title 20 bold darkBlue.
  - Form fields with prefix icon container (8 pad bg `primaryBlue × 10%`):
    Name, Phone (`phone` keyboard), and (patient only) Height + Weight
    Row.
  - Save Changes gradient button.
  - On save: write local + backend (`PUT /user/me`), show success
    snackbar (accentTeal bg).
- **Image picker bottom sheet** (mobile only): COMPONENT_INVENTORY
  §B.23. On web replace with `<input type="file">` + react-easy-crop.
- **Loading state:** none (data lives in Hive); profile defaults to "—"
  if a field is missing.

---

### 9.11 Settings (`/settings`)

- **Source:** `lib/screens/settings/settings_screen.dart`.
- **AppBar:** white, "Settings" bold darkBlue.
- **Body:** plain (no `DecoratedBackground`), 24 padding.
- **Items:**
  - SwitchListTile "Notifications" / sub-text "Receive alerts and
    reminders" — `enableNotifications` Hive toggle. Active thumb
    `primaryBlue`.
  - 16 spacer.
  - DropdownButton tile "Language" — current language as subtitle,
    `arrow_drop_down` primaryBlue. Items: English, العربية.
- **Entry animations:** `AnimatedListItem` per row (index 0, 1).

---

### 9.12 AI Report History (`/report_history`, doctor view)

- **Source:** `lib/features/ai_assessment/screens/report_history_screen.dart`.
- **Doctor entry:** Patient detail → "View AI reports" → pushes route
  with `isDoctorView: true, patientId, patientName`.
- **RTL:** forced via `Directionality(textDirection: TextDirection.rtl)`.
- **Background:** `AssessmentColors.background` (`#F0F5FF`).
- **Header** (custom, no Material AppBar):
  - Padding `(top: safeArea + 8, h: 20, b: 20)`.
  - `headerGradient` (`#407BFF → #00B4D8`).
  - Bottom rounded 28.
  - Shadow `0 8 20 primaryBlue × 30%`.
  - Left: `arrow_forward_ios_rounded` 18 white (inside white-20% radius-12 chip).
  - Center column: title "التقارير السابقة" 20 bold Cairo white + subtitle
    "سجل تقارير القلب" 13 Cairo white/70.
  - Right: `refresh_rounded` 20 white in same chip.
- **Body states:**
  - **Loading:** centered `CircularProgressIndicator(AssessmentColors.primary)`.
  - **Error:** custom error widget (icon + message).
  - **Empty (doctor):** centered column with 24-padded `primarySurface`
    circle containing `article_outlined` 60 primary; title "لا توجد تقارير
    لهذا المريض حتى الآن" 20 bold Cairo `textPrimary`.
  - **List:** padded `(20,20,20,24)` ListView of report cards.
- **Report card** (`_buildReportCard`):
  - White card radius 20 + 16 margin-bottom + `AssessmentShadows.card`
    (`0 8 24 primary × 8%`).
  - Padding 16.
  - 12-padded `primarySurface` radius-14 leading icon container with
    `description_rounded` 24 primary.
  - 14 gap.
  - Title "تقرير رقم {n}" 16 bold Cairo `textPrimary` + 4 spacer +
    row of `calendar_today_outlined` 14 muted + 6 gap + date text 13
    Cairo secondary.
  - Right pill "مكتمل" (h 10, v 4, radius 12) bg `success × 10%`,
    text 11 bold Cairo success.
- **Behavior:** tapping a card pushes `ReportResultScreen` with the
  report (full Markdown-ish report rendered separately).

---

### 9.13 No-Internet & Server-Down full-page states

- **NoInternetView** (`lib/widgets/reusable/no_internet_view.dart`):
  - Background `#F8FAFC`.
  - Top-right radial gradient circle (300×300, primaryBlue 10% → transparent).
  - Center column:
    - Pulse-scaling white circle (32 padding) with shadow
      `0 0 30 primaryBlue × 20% spread 10` containing `wifi_off_rounded`
      80 primaryBlue.
    - 50 spacer.
    - Title `noInternetTitle` 24 bold darkBlue.
    - 16 spacer.
    - Description `noInternetDesc` 16 darkBlue/60 `height: 1.5`.
    - 40 spacer.
    - Row 16×16 spinner (primaryBlue) + 12 gap + label `reconnecting` 14 w600
      primaryBlue.
- **ServerDownView** (`lib/widgets/reusable/server_down_view.dart`):
  - Same structure but central icon = `dns_rounded` 64 redAccent on a
    24-padding white circle with shadow `0 0 20 redAccent × 30% spread 5`,
    surrounded by 3 radar-ripple rings (scale 1 → 2.5, opacity 1 → 0,
    3 s loop, 0.33 s stagger). Title `serverDownTitle`, description
    `serverDownDesc`. Polling: 5 s `Timer.periodic` calling
    `onRefresh()`; cancels on success.

---

### 9.14 Toast / Snackbar overlay (global)

- **AnimatedToast** is rendered via `OverlayEntry` triggered by
  `NotificationService.showSuccess/Error/Warning/Info/HeadsUp`.
- Anchored top center (50 px from top, 16 h margin).
- Auto-dismiss after 4 s. Swipe up dismisses.
- **Web equivalent:** sonner / Radix `<Toast>` anchored top-right
  (desktop) or top-center (mobile web), with the same color tokens.

---

## 10. Page-by-page Tailwind layout sketches

For convenience, here are sketch-level Tailwind structures the web team
can start from. These are templates, not finished components.

### 10.1 Doctor dashboard layout shell

```tsx
<div className="min-h-screen flex bg-background text-dark-blue">
  <Sidebar />                                          {/* 240–280 px */}
  <main className="flex-1 flex flex-col min-h-screen">
    <Topbar />                                         {/* 64 px sticky */}
    <Outlet />                                          {/* current page */}
  </main>
</div>
```

### 10.2 Dashboard page

```tsx
<DecoratedBackground>
  <Hero />                                              {/* gradient header */}
  <section className="p-6 grid grid-cols-2 md:grid-cols-4 gap-4">
    <StatCard … />…
  </section>
  <section className="px-6">
    <AlertCard … />                                     {/* if critical */}
  </section>
  <section className="px-6 mt-6">
    <SectionTitle title="Recent Patients" action="See All" />
    <div className="space-y-4">…<PatientCard /></div>
  </section>
</DecoratedBackground>
```

### 10.3 Patient detail page

```tsx
<header className="bg-white border-b">
  <BackButton /> Patient Details <RemovePatientButton />
</header>
<DecoratedBackground>
  <div className="max-w-screen-md mx-auto p-6 space-y-6">
    <PatientInfoCard … />
    <StatusCard … />
    <section>
      <header className="flex items-center justify-between">
        Vitals  <ViewChartsPill />
      </header>
      <div className="grid grid-cols-2 gap-4 mt-4">…<VitalCard /></div>
    </section>
    <ViewReportsButton />
    <PatientBioSection />
  </div>
  <FloatingActions />
</DecoratedBackground>
```

(Continue similarly for chat, vitals, appointments, notifications,
profile, settings, report history.)

---

End of DESIGN_SYSTEM.md.
