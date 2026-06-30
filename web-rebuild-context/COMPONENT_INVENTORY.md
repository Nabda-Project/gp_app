# COMPONENT_INVENTORY.md — Exhaustive Component Reference

> Every reusable widget, every inline component in the doctor screens,
> with full props, visual specs, states (loading/empty/error/disabled),
> usage by role, and a concrete web translation.
>
> Citations use `path:line`. Color tokens follow DESIGN_SYSTEM.md.

---

## A. Reusable widgets (`lib/widgets/`)

### A.1 `PatientCard`

- **File:** `lib/widgets/reusable/patient_card.dart` (entire file).
- **Purpose:** Single-row patient summary used in the doctor dashboard's
  "Recent Patients" and in the "My Patients" tab.
- **Used by:** Doctor only.
- **Props (constructor at `:17-29`):**
  - `name: String` (required)
  - `email: String` (required)
  - `status: String` (required) — one of `'Normal' | 'Warning' | 'Critical'`
  - `heartRate: String` (required) — formatted BPM or `'--'`
  - `lastUpdate: String` (required) — free-form; empty hides the chip
  - `onTap: VoidCallback?`
  - `onMessageTap: VoidCallback?`
  - `onDeleteTap: VoidCallback?`
  - `highlightText: String?` — substring to highlight in name (search)
  - `profileImageUrl: String?`
- **Visual spec:**
  - Card: 16 px radius, white bg, margin-bottom 16 (paddingM).
  - Critical: extra 1.5 px border `error × 30%`.
  - Shadow: `0 4 12 statusColor × 10%`.
  - Padding inside: 16 (paddingM).
  - Avatar 26 px radius (`UserAvatar`) with 14×14 status dot bottom-right
    (`white` 2 px border).
  - Status dot color = `statusColor` derived from `status` prop
    (`:31-40`): `Warning → Colors.orange`, `Critical → error`, default → `accentTeal`.
  - Right column actions stacked vertically with 6 gap:
    - Message: 8 padding bg `primaryBlue × 10%`, radius 10, icon
      `message_outlined` 18 px `primaryBlue`.
    - Delete: 8 padding bg `error × 8%`, radius 10, icon `delete_rounded`
      18 px `error`.
  - Body row: name (15 px bold `darkBlue`, ellipsis 1 line) + Wrap of
    info chips (8 spacing, 4 run): HR pill (icon `favorite` red 12,
    text 11 w500 redAccent), and "lastUpdate" pill (icon `access_time`
    grey 12, text 11 w500 grey) — only if `lastUpdate.isNotEmpty`.
- **Search highlight (`:187-232`):** Splits the name into `TextSpan`s
  where any case-insensitive match of `highlightText` is rendered with
  `backgroundColor: primaryBlue × 20%`, color `primaryBlue`, bold.
- **States:**
  - Default / Normal / Warning / Critical (visual only).
  - No explicit loading state (parent shows a `ListSkeleton`).
  - No disabled state.
- **Web translation:**

```tsx
<article
  className="
    relative w-full p-4 mb-4 bg-white rounded-2xl
    transition shadow-[0_4px_12px_var(--status-shadow)]
    [--status-shadow:rgba(0,191,165,0.10)]
    data-[status=Warning]:[--status-shadow:rgba(255,152,0,0.10)]
    data-[status=Critical]:[--status-shadow:rgba(229,57,53,0.10)]
    data-[status=Critical]:border data-[status=Critical]:border-[1.5px] data-[status=Critical]:border-error/30
    hover:shadow-lg cursor-pointer
  "
  data-status={status}
>
  …
</article>
```

For the avatar dot, position absolutely at `bottom-0 right-0` and use
`bg-[var(--status-color)]` with the same color rules.

---

### A.2 `StatCard`

- **File:** `lib/widgets/reusable/stat_card.dart`.
- **Purpose:** KPI tile in the doctor dashboard (Total patients, Need
  attention, Pending messages, Today's appointments, Missed
  appointments).
- **Used by:** Doctor; patient dashboard reuses similar idea but uses
  different copy.
- **Props (`:17-23`):** `icon: IconData`, `value: String`, `label: String`,
  `color: Color`, `onTap: VoidCallback?`.
- **Visual spec:**
  - Card: 14 px radius, `clipBehavior: antiAlias`, white bg.
  - Padding: h 14, v 10.
  - Shadow: `0 4 10 color × 10%`.
  - Animated 3 sec sin loop background (`_StatCardBgPainter`,
    `:172-198`) drifts three faint gradient circles (opacity ~0.02–0.05).
  - Decorative large background icon at bottom-right (`right:-10, bottom:-10`),
    size 70, opacity sin-animated 0.03–0.06 (`:82-99`).
  - Inner row: animated icon container 8 padding, radius 10,
    `color × ~0.10` bg with `color × ~0.05` glow shadow (sin loop).
  - Value (right of icon): FittedBox-scaled 26 px / w800 / `color` /
    `height: 1.0`.
  - Label below: 12 px / bold / `grey`, max 2 lines, ellipsis.
  - Aspect ratio in grid: 1.5 (`doctor_dashboard_screen.dart:849`).
- **States:** all visual; no loading / error / disabled.
- **Web translation:** static card with `:hover` lift; skip the
  per-frame painter on web for performance (use a static SVG mesh or
  none).

```tsx
<button
  type="button"
  onClick={onTap}
  className="
    relative overflow-hidden rounded-[14px] bg-white text-left
    px-3.5 py-2.5 shadow-[0_4px_10px_var(--c)/10]
    transition hover:shadow-[0_6px_14px_var(--c)/20]
    aspect-[3/2]
  "
  style={{ '--c': color } as React.CSSProperties}
>
  <Icon
    name={icon}
    className="absolute -right-2.5 -bottom-2.5 w-[70px] h-[70px] opacity-[0.04]"
    style={{ color }}
  />
  <div className="flex items-center gap-2.5 relative">
    <div className="p-2 rounded-[10px]" style={{ background: `${color}1A` }}>
      <Icon name={icon} size={22} style={{ color }} />
    </div>
    <div className="min-w-0">
      <div className="text-2xl font-extrabold leading-none" style={{ color }}>{value}</div>
      <div className="mt-1 text-xs font-bold text-grey line-clamp-2">{label}</div>
    </div>
  </div>
</button>
```

---

### A.3 `AlertCard`

- **File:** `lib/widgets/reusable/alert_card.dart`.
- **Purpose:** Top-of-dashboard banner when critical patients exist.
- **Used by:** Doctor.
- **Props (`:12-20`):** `title, message, onTap`, `buttonText='View'`,
  `color=AppColors.error`, `icon=Icons.warning_rounded`.
- **Visual:** Gradient `color × 10% → 5%`, border `color × 30%`, radius
  14 px, padding 16. Icon container 10 padding bg `color × 20%` radius
  10. Title 14 bold `color`; message 12 `color × 80%`. Right TextButton
  `color` bold.
- **States:** static.
- **Web translation:** `<aside role="alert">` with the same gradient via
  Tailwind arbitrary `bg-[linear-gradient(...)]`.

---

### A.4 `StatusCard`

- **File:** `lib/widgets/reusable/status_card.dart`.
- **Purpose:** Health status indicator on Patient Detail.
- **Used by:** Doctor (via Patient Detail).
- **Props:** `title, status, healthStatus`. `healthStatus` ∈
  `{CRITICAL, WARNING, NORMAL, UNKNOWN}`.
- **Visual:**
  - Outer 16 px radius white card.
  - Shadow: `0 6 20 accentColor × glowOpacity` where `glowOpacity` =
    `0.10 + 0.08*sin(t)` for non-unknown; `0.05` flat for unknown.
  - Animated background painter (2.5 sec loop):
    - Healthy: a moving radial highlight sweep from left → right.
    - Warning/Critical: 3 concentric pulsing rings at right edge.
    - Unknown: no painter.
  - Left vertical accent border 4 px in `accentColor`.
  - Inside (24 padding L):
    - Icon container 12 padding circle bg `accent × (8 or animated 10–15)%`,
      with shadow `0 0 12 accent × glowOpacity*0.4` (unless unknown).
    - Icon: `error_rounded` / `warning_rounded` / `check_circle` /
      `help_outline_rounded` (28 px, in accent color).
    - Right column: title 14 grey + value 24 bold accentColor.
- **Icon→state mapping (`:62-74`):** see DESIGN_SYSTEM §1.3.
- **States:** four healthStatus values; no other states.
- **Web:** SVG/CSS layered animation or static if not worth porting.
  Always render the colored left border + icon + title + status text.

---

### A.5 `VitalCard`

- **File:** `lib/widgets/reusable/vital_card.dart`.
- **Purpose:** 2×2 vital grid on Patient Detail.
- **Used by:** Doctor (Patient Detail uses `subtleMode: true`).
- **Props:** `label, value, unit, icon, color, subtleMode=false`.
- **Visual:**
  - 16 px radius white card, border `color × 15%`, shadow `0 6 16 color × 12%`.
  - Per-icon animated background painter (mobile only):
    - `Icons.favorite` → realistic ECG PQRST scrolling line
      (`_HeartbeatPainter`, `:204-338`).
    - `Icons.water_drop` → 7 rising bubbles (`:340-417`).
    - `Icons.battery_charging_full` → wave fill proportional to value
      `(fillFraction)` (`:426-503`).
    - Otherwise → 3 concentric pulsing rings (`:506-567`).
  - `subtleMode = true` multiplies all animation opacities by 0.35.
  - Content padding: 8 horizontal / 8 vertical. Centered column:
    - Icon container 6 padding, `color × 12%` circle, icon size 18, color.
    - Value text 15 px bold `darkBlue` + unit text 11 px grey.
    - Label below: 12 px w600 darkBlue, centered, max 2 lines.
- **States:** purely visual; "no data" handled by the caller passing
  `value: '--'`.
- **Web translation:** render static cards. The PQRST waveform is the
  one painter worth a stretch goal (inline SVG with a stroke-dashoffset
  animation moving the curve).

---

### A.6 `UserAvatar`

- **File:** `lib/widgets/reusable/user_avatar.dart`.
- **Purpose:** Universal avatar renderer; handles URLs, base64 data
  URIs, local file paths, and fallback initials/icon.
- **Used by:** Everyone (doctor + patient).
- **Props:** `imageUrl?, name?, radius=20, backgroundColor?, foregroundColor?, fallbackIcon=Icons.person, iconSize?`.
- **Resolution order (`:69-121`):**
  1. URL with `http://` or `https://` → `CachedNetworkImage` with a
     **shimmer placeholder** (shimmer base `bg × 30%`, highlight
     `white × 60%`).
  2. URL with `data:image…` → decode base64 once; cache up to 30 in a
     static LRU; render via `MemoryImage`.
  3. Non-empty path that exists on disk → `FileImage`.
  4. Else → fallback: if `name` present, big first-letter initial
     (radius × 0.8 size, color `fg`); else icon (radius × 0.9 size).
- **Default colors:** `bg = primaryBlue × 10%`, `fg = primaryBlue`.
- **States:**
  - Loading: shimmer circle.
  - Error: fallback initial/icon.
  - Disabled: n/a.
- **Web translation:** `<img loading="lazy">` with `onError` swapping to
  the initial-letter fallback. Wrap in a circular `<div>`. Web does not
  need the LRU base64 cache (browsers cache `data:` URIs implicitly),
  but very large lists should use `<canvas>` thumbnails or React-Window
  to limit DOM weight.

---

### A.7 `DecoratedBackground`

- **File:** `lib/widgets/reusable/decorated_background.dart`.
- **Purpose:** Standard page background with three decorative blurred
  circles. See DESIGN_SYSTEM §3.7 for the CSS port.
- **Used by:** Doctor dashboard, Patients, Patient Detail, Vitals,
  Notifications, Appointments, Profile, Chats list.
- **Props:** `child, showTopCircle=true, showBottomCircle=true, circleColor?`.

---

### A.8 `CustomBottomNavBar`

- **File:** `lib/widgets/reusable/custom_bottom_nav.dart`.
- **Purpose:** Mobile bottom navigation (Doctor + Patient dashboards).
- **Visual:** Floating pill — margin 16, white bg, radius 30,
  shadow `0 10 30 primaryBlue × 15%`, padding 8 h / 8 v.
- **Item visual:**
  - Unselected: only icon (size 22, `grey`).
  - Selected: animated container expands to `padding (h:12, v:12)` with
    `primaryBlue × 10%` bg, radius 20. Icon at 24 px `primaryBlue` + label
    13 w600 `primaryBlue`.
  - Animation: 300 ms `easeOutCubic`.
- **Badge:** top-right (-6, -8), padding (h:4, v:1), min size 16,
  redAccent bg, white 1.5 border, 9 pt bold white text; shows `'99+'`
  when count > 99.
- **Web equivalent:** Sidebar instead. Keep the badge logic.

```tsx
<aside className="hidden md:flex flex-col fixed inset-y-0 left-0 w-64 bg-white border-r border-light-grey/50 px-4 py-6">
  …
</aside>
```

---

### A.9 `SectionTitle`

- **File:** `lib/widgets/reusable/section_title.dart`.
- **Visual:** `titleLarge` (24 px) w800 `darkBlue`. Optional right
  text button (`actionText`, `onAction`).
- **Web:** `<h2 class="text-4xl font-extrabold text-dark-blue flex items-center justify-between">`.

---

### A.10 `CustomCard` (role selection)

- **File:** `lib/widgets/reusable/custom_card.dart`.
- **Used by:** Role selection screen — **NOT in scope for the doctor web app**.
- Listed for completeness.

---

### A.11 `CustomButton`

- **File:** `lib/widgets/reusable/custom_button.dart`.
- **Purpose:** Primary CTA button used in Auth screen, dialogs, etc.
- **Props:** `text, onPressed, isContent=false, backgroundColor?, textColor?, useGradient=true, isLoading=false`.
- **Visual when `useGradient=true`:** full width, primaryGradient
  background, 24 px radius, vertical pad 18, shadow
  `0 6 12 primaryBlue × 35%`, text 18 bold letter-spacing 0.5 white.
- **Loading state (`:57-66`):** 20×20 white CircularProgressIndicator
  (stroke 2), no text.
- **Disabled state:** when `isLoading=true`, `onPressed: null` triggers
  default Material disabled behavior.
- **Web translation:** `<button class="w-full py-[18px] rounded-3xl bg-gradient-to-br from-primary to-secondary text-white text-lg font-bold tracking-wide shadow-[0_6px_12px_rgba(64,123,255,0.35)] disabled:opacity-60">`.

---

### A.12 `EmptyStateView`

- **File:** `lib/widgets/reusable/empty_state_view.dart`.
- **Purpose:** Generic "nothing here" state with optional action button.
- **Visual:**
  - Centered, padding 32.
  - Two nested circles: outer 28 padding `primaryBlue × 5%`; inner 24
    padding `primaryBlue × 10%`. Icon size 64 in `primaryBlue × 60%`.
  - Title 20 / w700 / darkBlue.
  - Description (optional) 15 / regular / grey × 80%, `height: 1.5`.
  - Action (optional): `OutlinedButton.icon`, refresh icon size 20,
    label 15 w600, `primaryBlue` foreground, border `primaryBlue × 30%`
    1.5 width, padding (h 24, v 12), radius 12.
  - Wrapped in `FadeSlideTransition` (delay 100 ms).
- **Usage:** patients list errors/empty, appointments list, AI report
  history, chat list, notifications, etc.
- **Web:** `<section role="status" aria-live="polite">` matching the
  same nested circle visual.

---

### A.13 `NoInternetView`

- **File:** `lib/widgets/reusable/no_internet_view.dart`.
- **Visual:** background `background`. Top-right decorative gradient
  circle. Centered ScaleTransition (1.0 → 1.1, 2 s reverse loop) wraps
  `wifi_off_rounded` 80 px on a white 32-padding circle with shadow
  `0 0 30 primaryBlue × 20% spread 10`. Title 24 bold `darkBlue`,
  description 16 `darkBlue × 60%` `height: 1.5`. Bottom row: 16×16 spinner
  `primaryBlue` + label "Reconnecting…" w600 `primaryBlue`.
- **Translation keys:** `noInternetTitle`, `noInternetDesc`,
  `reconnecting`.

---

### A.14 `ServerDownView`

- **File:** `lib/widgets/reusable/server_down_view.dart`.
- **Visual:** 200×200 box at center with 3 ripple-rings (`redAccent × 50%`,
  scale 1 → 2.5, opacity 1 → 0, 3 s loop, staggered 0.33). Center
  pulsing icon `dns_rounded` 64 px `redAccent` on white 24-padding
  circle with shadow `0 0 20 redAccent × 30% spread 5`. Title 24 bold,
  description 16 muted, bottom row reconnecting indicator like
  NoInternet.
- **Polling:** `Timer.periodic(5s)` calling `onRefresh` until it returns true.
- **Web port:** CSS ripple keyframes + same icon. Replace `Timer` with
  `setInterval(5000)` (or stop after success).

---

### A.15 `DashboardSkeleton`

- **File:** `lib/widgets/reusable/dashboard_skeleton.dart`.
- **Purpose:** Shimmer placeholder for the dashboard while gating
  network/server. Uses `shimmer` package, `grey[300] → grey[100]`.
- **Structure:** SliverAppBar shell (180 height), avatar circle 58, two
  text lines 60/14 + 140/22, status pill 100/24, action 44/44; body has
  a 100-height white card, 80-height card, "section title" 100/20,
  2×2 grid of empty cards.
- **Web:** `<div className="animate-pulse">` of the same layout with
  `bg-light-grey` blocks.

---

### A.16 `ListSkeleton`

- **File:** `lib/widgets/reusable/list_skeleton.dart`.
- **Props:** `itemCount=6, hasAvatar=true, compact=false`.
- **Visual:** Each row: optional 50×50 (or 40×40 if compact) circular
  block + two text bars (full width 14 px + 120×12 + maybe 80×10),
  trailing 40×20 block. Rounded card 16 with 1 px grey-200 border.
  Shimmer base `grey[200] → grey[50]`.

---

### A.17 `LogoutDialog`

- **File:** `lib/widgets/reusable/logout_dialog.dart`.
- **Purpose:** Confirmation dialog for logout. Static
  `LogoutDialog.show(context, navigateToRoute='/onboarding')`.
- **Visual:**
  - Dialog 20 px radius, elevation 16.
  - 24 padding container.
  - Icon container 16 padding, circular, gradient `error × 10% → 5%`
    (TopLeft → BottomRight). Icon `logout_rounded` 40 px `error`.
  - Title 22 bold `darkBlue` ("Logout").
  - Description 15 grey `height: 1.4` ("Are you sure you want to log out?").
  - Buttons row (12 gap):
    - Cancel: OutlinedButton, border `grey × 30%` 1.5, radius 12,
      vertical 14, label 15 w600 `darkBlue`.
    - Logout: ElevatedButton bg `error`, radius 12, vertical 14, white
      label 15 w600.
- **Action (`:39-56`):** signs out (Firebase + token + ChatService +
  DioClient reset) and `pushNamedAndRemoveUntil(route)`.
- **Web:** Radix Dialog with same visuals.

---

### A.18 `AnimatedToast`

- **File:** `lib/widgets/reusable/animated_toast.dart`.
- **Props:** `title, message, type ('success'|'error'|'warning'|'info'), onDismiss`.
- **Visual:**
  - Positioned `top: 50, left: 16, right: 16`.
  - Container 12 v / 16 h, 16 px radius.
  - Background: white (light) or `#1E1E1E` (dark).
  - Shadows: `0 4 12 typeColor × 20%` + `0 1 4 black × 5%`.
  - Border: 1 px `typeColor × 10%`.
  - Icon container 8 padding circle bg `typeColor × 10%`. Icon 24 px
    `typeColor`.
  - Title 14 w600.
  - Message 12 (`bodyMedium × 70%`).
  - Trailing close icon (20 px, opacity 50%).
- **Animation:**
  - Forward 600 ms (`Curves.elasticOut`), reverse 400 ms (`easeIn`),
    slide from `Offset(0, -1)` to `Offset.zero`.
  - Auto-dismiss after 4 s (`notification_service.dart:73-75`).
  - Swipe up to dismiss (`DismissDirection.up`).
- **Web:** sonner/Radix Toast at the top center, with a slight overshoot
  curve.

---

### A.19 `AssignPatientSheet`

- **File:** `lib/widgets/reusable/assign_patient_sheet.dart`.
- **Purpose:** Mobile modal bottom sheet for searching and assigning a
  patient. **Doctor-only.**
- **Trigger:** `AssignPatientSheet.show(context, doctorId, onAssigned)`.
- **Visual structure:**
  - `showModalBottomSheet(isScrollControlled: true, transparent bg)`.
  - Outer container max-height 85% of screen, bg `background`
    (`#F8FAFC`), top-rounded 24.
  - Drag handle: 40×4 pill `grey × 30%`, radius 2, margin-top 12.
  - Header row (`:294-336`): 10 padding gradient (primaryGradient) icon
    container radius 12 (icon `person_add_rounded` 22 white), title
    "Assign Patient" (20 bold darkBlue), close button (lightGrey × 50%
    circle, icon `close` 18 grey).
  - Mode toggle (`:341-371`): segmented bg `lightGrey × 40%` radius 12,
    4 padding. Each button vertical pad 10, radius 10. Selected:
    white bg + shadow `0 2 6 black × 6%`. Icon + label 13.
  - Search field (`:376-438`): white card radius 14, shadow
    `0 2 10 black × 5%`. Prefix icon (search/phone) `primaryBlue`. Suffix
    `clear` button when text. Content padding 16 h / 14 v. Auto-focus.
  - Error banner (`:444-491`): 12 padding 12 radius bg `error × 8%`
    border `error × 20%` with `error_outline` 20, message text 13 w500
    `error`, "Retry" TextButton.
  - Result tile (`:630-771`):
    - White card radius 14, shadow `0 2 8 black × 4%`, padding 14.
    - Avatar 48×48 radius 14, gradient `primaryBlue × 15% → secondaryBlue × 10%`,
      centered initial 20 bold `primaryBlue`.
    - Name 15 w600 darkBlue. Email 12 grey. Phone (with icon 12 grey)
      below.
    - "Assign" pill on the right: padding (h 14, v 8), radius 10,
      `primaryGradient`, shadow `0 2 8 primaryBlue × 25%`, label 13 w600
      white.
- **States:**
  - Initial (no query / < 2 chars): grey `person_search_rounded` 56,
    label `typeToSearch` 14 grey.
  - Searching: 32 px CircularProgressIndicator stroke 3 primaryBlue +
    label `searching`.
  - Empty results: `search_off_rounded` 56 grey × 30% + `noResults`.
  - Error: shown via the banner above; results area shows nothing if
    no prior results.
  - Assigning: replaces the "Assign" pill with a 24×24 spinner
    (`stroke: 2`).
- **Debounce:** 500 ms after typing.
- **Min query length:** 2.
- **Web translation:** centered `<dialog>` (max-w 480) with the same
  structure — keep the drag handle off (mobile metaphor).

---

### A.20 `AppLogo`

- **File:** `lib/widgets/reusable/app_logo.dart`.
- **Purpose:** Procedural ECG line inside a white circle.
- **Props:** `size=150, animate=false, animation?`.
- **Visual:** white circle, shadow `0 10 20 primaryBlue × 20%`. ECG path
  drawn via `_HeartbeatPainter` using normalized waypoints (see
  `:117-131`). Stroke width = `size × 0.03` for the main path + a 6×
  `0.06`-width blurred glow.
- **Used in:** splash 120, auth 80.
- **Web:** inline SVG (see ASSET_MANIFEST.md §2 for waypoints). Animate
  via `stroke-dasharray` + `stroke-dashoffset` for the draw-in.

---

### A.21 `FadeSlideTransition`

- **File:** `lib/widgets/animations/fade_slide_transition.dart`.
- **Props:** `child, duration=500ms, delay=0, beginOffset=Offset(0,0.1), curve=easeOutCubic`.
- **Behavior:** combine fade 0→1 + slide from `beginOffset` → zero.
- **Web:** framer-motion `initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }}`.

---

### A.22 `AnimatedListItem`

- **File:** `lib/widgets/animations/animated_list_item.dart`.
- **Props:** `child, index, duration=400ms, staggerDelay=80ms,
  beginOffset=Offset(0,0.15), curve=easeOutCubic`.
- **Behavior:** staggered entrance per index.
- **Web:** framer-motion's `staggerChildren: 0.08` or a custom CSS
  variable-driven `animation-delay: calc(var(--i) * 80ms)`.

---

### A.23 `ScaleOnTap`

- **File:** `lib/widgets/animations/scale_on_tap.dart`.
- **Props:** `child, onTap, scaleValue=0.95, duration=100ms`.
- **Behavior:** scale down on press, ease-in-out, then run `onTap`.
- **Web:** `active:scale-95 transition-transform` plus a Tailwind
  `motion-safe:` modifier.

---

## B. Inline / screen-local components

Although these are not extracted into separate widget files, they are
repeated patterns the web app should componentize.

### B.1 Doctor dashboard hero header (SliverAppBar)

- **Source:** `doctor_dashboard_screen.dart:665-833`.
- **Visual:**
  - Height 170 (expanded). White solid background.
  - Inner stack:
    - `primaryGradient` Container filling the area.
    - 200×200 white circle at `(top:-60, right:-30)`, opacity 0.08.
    - 140×140 white circle at `(bottom:-20, left:-40)`, opacity 0.08.
    - SafeArea padding 24 with bottom-left aligned Row:
      - White-bordered (3 padding, 20% bg) circular avatar wrapper
        containing `UserAvatar` 26 px (`fallbackIcon: medical_services`).
      - 16 gap.
      - Column: "Hello" 14 white/90, "Dr. {fullName}" 22 bold white,
        date pill ("Wed, Apr 1") 12 w500 white with 8/3 padding bg
        white/15 radius 12.
      - Notification icon button (bg `white × 15%`, radius 12) with a
        12×12 red dot (white 1.5 px border) when `_unreadNotifCount > 0`.
      - 8 gap, Calendar icon button (same style).
- **Behavior:** sticky on scroll, partial collapse.
- **Web equivalent:** sticky `<header class="bg-gradient-to-br from-primary to-secondary text-white">`
  with the same content stacked left, decorative circles via
  `::before`/`::after`.

### B.2 Profile hero header

- **Source:** `profile_screen.dart:550-731`.
- **Height:** 280 px.
- **Structure:** `primaryGradient` bg + two white circles at
  `(top:-60,right:-30, 200×200, 8%)` and `(bottom:-20,left:-40, 140×140, 8%)`.
  Logout icon button top-right `white × 15%` circle, padding 10.
  Centered column: avatar wrapper (4 padding circle border `white × 50%` 3 px),
  CircleAvatar 50 px (white/20 bg, FileImage if local). Bottom-right of
  avatar: 6-padding accent-teal circle `white × 2 px border` with icon
  `camera_alt` 16 white. Below: name 22 bold white, email 14 white/85,
  role pill (h 14, v 4) `white × 20%` radius 20 (text 12 w600 white).
- **Web equivalent:** `<header>` with grid: avatar centered + name +
  email + role pill. Logout button absolute top-right.

### B.3 Chat tile (doctor dashboard "Chats" tab)

- **Source:** `doctor_dashboard_screen.dart:1246-1427`.
- Each row: white card radius 16, shadow `0 3 10 black × 4%`. Padding
  16 h / 14 v. Avatar 26 with online dot (14 px, teal/grey, white
  2.5 border). Center: name 15 bold darkBlue, last-message preview 13
  `grey × 80%`. Right: timestamp 11 grey + row of (unread badge,
  status pill).
  - Unread badge: padding (h 7, v 2), radius 10, primaryBlue, 11 w bold
    white.
  - Status pill: padding (h 8, v 2), radius 10, bg
    `(online ? teal : grey) × 10%`, text 10 w600 same color.

### B.4 Appointment card

- **Source:** `doctor_appointments_screen.dart:421-650`.
- Card: white radius 20, shadow `0 8 15 darkBlue × 5%`, margin-bottom
  24.
- **Top section** (`statusColor × 5%` bg, top corners 20):
  - 10 padding white circle with shadow `0 3 8 statusColor × 20%`. Icon
    (`check_circle` / `cancel` / `event_available`) 20 statusColor.
  - 16 gap. Name 16 bold darkBlue. Reason 13 grey (one-line ellipsis).
  - Right pill `statusColor` solid, padding (h 10, v 6), radius 12,
    text 11 bold white = appointment.status.
- **Bottom section** (16 padding):
  - Date row: 8 padding `lightGrey × 50%` 10-radius square with
    `calendar_month` 16 primaryBlue. 12 gap. Date text 14 w600 darkBlue
    (`EEEE, MMM d, yyyy`).
  - Time row (12 gap): same icon container with `access_time_filled`
    16 orange. Time text 14 w600 darkBlue (`h:mm a`).
  - SCHEDULED only: 12 vertical pad divider `lightGrey × 50%`, then
    actions:
    - "Cancel": TextButton.icon, close 16 redAccent, label 16 w600
      redAccent.
    - "Complete": ElevatedButton.icon, check 16, label "Complete" on bg
      `Colors.green`, padding (h 16, v 10), radius 12, elevation 0.

### B.5 Appointments grouped section header

- **Source:** `doctor_appointments_screen.dart:381-419`.
- Row of icon container (8 padding `primaryBlue × 10%` radius 12 with
  20 primaryBlue icon) + 12 gap + title (18 w800 darkBlue letter-spacing
  0.5) + 16 gap + Expanded Divider (thickness 1.5 `lightGrey × 50%`).

### B.6 Date separator (chat)

- **Source:** `patient_chat_screen.dart:543-582`.
- Divider 0.8 thick `grey × 25%` on each side of a centered chip:
  padding (h 12, v 4), radius 12, bg `grey × 8%`, label 12 w500
  `grey × 70%` ("Today" / "Yesterday" / day name / `MMM d, yyyy`).

### B.7 Chat message bubble

- **Source:** `patient_chat_screen.dart:584-690`.
- Row aligned end/start by `isMe`. Other-party shows avatar (12 radius,
  iconSize 14) on left with 8 gap.
- Bubble container: padding (h 16, v 12), max-width 75% of viewport,
  radius: `topLeft/topRight 20`; `bottomLeft = isMe ? 20 : 4`,
  `bottomRight = isMe ? 4 : 20`.
- Me bubble: `primaryGradient`, no border.
- Other bubble: white bg, 1 px border `grey × 10%`.
- Shadow: `0 4 10 (primaryBlue OR black) × 6%`.
- Content: text 15 `(white OR darkBlue)`, `height: 1.4`.
- Bottom row inside bubble: timestamp 11 w500 (white/80 or grey/80), and
  for "me" — read tick (`remove_red_eye_rounded` 14 white) /
  delivered (`done_all_rounded` 14 white/90) / sent (`check_rounded` 14
  white/70).

### B.8 Patient detail bio info chip (`patient_detail_screen.dart:496-547`)

- Container padding (h 12, v 10), bg `primaryBlue × 5%`, radius 12,
  border `primaryBlue × 10%` 1 px.
- Icon container 6 padding `primaryBlue × 10%` radius 8 with 16
  primaryBlue icon.
- 8 gap + label 11 w500 `grey × 80%` and value 13 w700 darkBlue.

### B.9 Patient detail FAB stack

- **Source:** `patient_detail_screen.dart:291-325`.
- Two extended FABs vertically (16 gap):
  - **Schedule Appointment** — white bg, primaryBlue icon
    (`calendar_month`) + label 16 bold primaryBlue.
  - **Send Message** — `primaryBlue` bg, white icon (`message`) + white
    label.
- Web: replace with a sticky right-side action bar OR top-right buttons
  on the patient detail page.

### B.10 Patient vitals live cards row

- **Source:** `patient_vitals_screen.dart:347-484`.
- Row of 3 expanded cards (12 gap):
  - HR: gradient red `#FF5252 → #FF1744`, padding 16, radius 20,
    shadow `0 6 12 #FF1744 × 30%`. Icon `favorite` 28 white pulsing
    (scale 1 → 1.15 via 1200 ms reverse loop). Value 28 bold white. "BPM" 12 white70.
  - SpO₂: gradient blue `#2196F3 → #1565C0`, same radius/padding/shadow.
    Icon `water_drop` 28 white. Value 28 bold white. "SpO2 %" 12 white70.
  - Battery: white bg, border `battColor × 30%`, shadow `0 6 12 black × 5%`,
    radius 20, padding 16. Icon (one of `battery_*`) 28 battColor.
    Value 28 bold battColor. "Battery %" 12 grey.

### B.11 Vitals chart container

- **Source:** `patient_vitals_screen.dart:486-627`.
- Padding 20, radius 20, gradient `#FDFDFF → #F5F7FC`, shadow
  `AppColors.cardShadow`.
- Row 1: title "Health Trends" 18 bold darkBlue + period selector pill
  (1 / 7 / 30 days).
- Row 2: 11 px grey/80 subtitle ("Chart shows hourly/daily averages • Shaded
  area shows raw min/max").
- Row 3: 3 metric toggles (`Heart Rate`, `SpO2`, `Both`) — each radius
  10, padding (h 12, v 6). Selected fill = color, unselected transparent
  with `lightGrey` 1 px border, text 12 w600.
  Spacer. Fit/Scroll mini-toggle.
- Chart area: `SfCartesianChart` from `syncfusion_flutter_charts`.
  Range-area band `color × 12%`, no border. Line stroke 2.5, marker
  6×6 circle with white 2 border.
  Tooltip: `#1E1E2E` bg, radius 8, white 11 text.
  Axis labels 10 grey, major grid 0.8 `lightGrey × 40%`.
- **Web alternative:** `recharts` ComposedChart with `Area` for
  min/max + `Line` for avg.

### B.12 Vitals stats summary

- **Source:** `patient_vitals_screen.dart:886-998`.
- White card radius 20, padding 20, shadow `cardShadow`.
- Top: title "Summary for today / Period Summary" 18 bold + chip
  primaryBlue × 10% radius 10 padding (h 10, v 4) text 11 w600 primaryBlue.
- 2×2 grid of stat tiles (12 gap). Each tile:
  - Padding 14, radius 14, bg `color × 6%`, border `color × 15%`.
  - Label 12 grey w500.
  - Optional subtitle 9 italic `color × 50%`.
  - Value 18 bold color.
  - Optional status pill 10 w600 `statusColor`, bg `statusColor × 15%`,
    padding (h 8, v 2), radius 8.

### B.13 Notification tile

- **Source:** `notifications_screen.dart:361-526`.
- Container 8 margin-bottom, radius 16, padding 16 h / 14 v.
- Read state: white bg, no border.
- Unread state: bg `typeColor × 6%`, border `typeColor × 15%` 1 px.
- Shadow: `0 2 8 black × 4%`.
- Row:
  - 44×44 icon tile radius 12 bg `typeColor × (8 if read, 15 if unread)%`,
    icon 22 (`grey` if read, `typeColor` if unread).
  - 16 gap.
  - Column: title 14 (w500 if read, bold if unread, darkBlue) + 8 gap +
    8 px circle if unread (typeColor); body 13 grey 2-line ellipsis;
    time 11 `grey × 70%`.
  - Right: 36×36 IconButton delete `delete_outline_rounded` 20
    `grey × 50%`.

### B.14 Connection banner (vitals)

- **Source:** `patient_vitals_screen.dart:203-256`.
- Container padding (h 16, v 10), radius 12, bg `bgColor × 10%`,
  border `bgColor × 30%`.
- Icon 18 + 8 gap + text 13 w600 + (if reconnecting) 14×14 spinner.
- Color rules:
  - load error + WS disconnected → `error` red.
  - WS reconnecting → `orange`.
  - WS disconnected → `error` red.
  - else → `orange`.

### B.15 Auth screen form field

- **Source:** `auth_screen.dart:906-948`.
- Filled `#F5F7FA`, radius 12, no border in idle, primaryBlue 1.5
  focused, error red 1 (1.5 focused error).
- Prefix icon `primaryBlue`. Optional suffix (visibility toggle).
- Validator `autovalidateMode: onUserInteraction`.

### B.16 Auth role toggle

- **Source:** `auth_screen.dart:609-628`, `:870-903`.
- Track: bg `#F5F7FA` radius 12 padding 4.
- Buttons: padding vertical 12, radius 10. Selected: white bg + shadow
  `0 2 4 black × 5%`, text bold primaryBlue. Unselected: transparent, grey.

### B.17 Profile section card

- **Source:** `profile_screen.dart:901-994`.
- White card radius 16, shadow `0 4 10 black × 5%`.
- Padding header (16 16 8 16) with title 16 bold darkBlue.
- Body list of `_buildInfoTile`s (icon, label, value) separated by
  `_buildDivider` (1 px `lightGrey × 50%` inset 16).
- Tile: 16 h / 10 v padding. Icon container 8 padding `primaryBlue × 8%`
  radius 10 + 14 gap. Column: label 12 w500 grey, value 15 w600 darkBlue.

### B.18 Profile option row

- **Source:** `profile_screen.dart:996-1034`.
- White card radius 12 with shadow `0 2 4 black × 5%`. ListTile with
  leading icon container (`primaryBlue × 10%`, 8 pad, 8 radius) and
  trailing `chevron_right` grey. Title bold darkBlue.

### B.19 Settings switch tile

- **Source:** `settings_screen.dart:122-154`.
- White card radius 12, shadow `0 2 4 black × 5%`.
- `SwitchListTile` with bold darkBlue title, grey subtitle, active thumb
  `primaryBlue`.

### B.20 Settings language dropdown

- **Source:** `settings_screen.dart:66-112`.
- White card radius 12, shadow. ListTile with `DropdownButton` (no
  underline), `arrow_drop_down` primaryBlue icon.

### B.21 Edit profile sheet save button

- **Source:** `profile_screen.dart:358-471`.
- Full-width container with primaryGradient, radius 14, shadow
  `0 4 12 primaryBlue × 30%`. Inside ElevatedButton transparent. Label
  "Save Changes" 16 bold white. Padding 16 v.

### B.22 Forgot-password dialog

- **Source:** `auth_screen.dart:235-439`.
- Dialog (radius 20, elevation 16). 24 padding. Icon container 16 padding
  gradient `primaryBlue × 15% → 5%` circle with `lock_reset_rounded`
  40 primaryBlue. Title 22 bold darkBlue. Description 14 grey
  `height: 1.4`. Email field (same style as auth fields, with prefix
  bg `primaryBlue × 10%` radius 8 8-padding container around the icon).
  Row of buttons (12 gap):
  - Cancel: OutlinedButton border `grey × 30%`, label 15 w600 darkBlue.
  - Send: container with primaryGradient + shadow, transparent
    ElevatedButton, label 15 w600 white.

### B.23 Image picker bottom sheet (profile)

- **Source:** `profile_screen.dart:147-247`.
- Drag handle 40×4 `grey × 30%`. Title "Change profile picture" 18 bold
  darkBlue. ListTile for "Take Photo" (camera icon 10-pad `primaryBlue × 10%`),
  "Choose from Gallery" (`accentTeal × 10%`), and (conditional) "Remove Photo"
  (`error × 10%`).

### B.24 SnackBar pattern (used widely)

- **Style across screens:** background = `accentTeal` for success, `error`
  for failure. `behavior: floating`, `shape: RoundedRectangleBorder(radius:12)`,
  margin 16 all sides. Content row of icon (`check_circle` / generic) +
  message label.
- **Examples:** patient assigned (`assign_patient_sheet.dart:181-188`),
  patient removed (`doctor_dashboard_screen.dart:488-507`), profile
  updated (`profile_screen.dart:432-451`), mark-all read
  (`notifications_screen.dart:151-159`).
- **Web equivalent:** sonner toast with the same color rules.

### B.25 Tab bar (Auth login/register)

- **Source:** `auth_screen.dart:496-507`.
- Default Material `TabBar` with `labelColor: primaryBlue`,
  `unselectedLabelColor: grey`, `indicatorColor: primaryBlue`. Two
  tabs.
- Web: `<Tabs.Root>` (Radix) styled with the same colors.

### B.26 Tab bar (Appointments)

- **Source:** `doctor_appointments_screen.dart:151-191`.
- Custom segmented control: outer container 24 h margin / 16 v margin,
  4 padding, bg `lightGrey × 40%`, radius 30. Inner `TabBar`:
  - `indicatorSize: tab`, indicator white bg + 26 radius + shadow
    `0 2 4 black × 5%`.
  - Labels 12 bold, `primaryBlue` selected / `grey` unselected. Height 48.

### B.27 Loading indicator pattern

- **Spinner color:** `primaryBlue` everywhere (vital chart,
  notifications loading, etc.).
- **Stroke width:** 2 typically, 3 for AssignPatient sheet, 2 for
  banners. 14×14 size in the connection banner; 20×20 in CustomButton;
  16×16 in NoInternet/ServerDown footer.

---

## C. Patient-specific components mentioned only for context

Documented for completeness because the doctor never sees them but the
backend payloads they generate flow into the doctor app.

| Widget                                                            | Doctor impact |
|-------------------------------------------------------------------|---------------|
| `lib/screens/patient/patient_dashboard_screen.dart`               | Generates vitals + assessment data the doctor consumes. |
| `lib/screens/patient/vitals_history_screen.dart`                  | Mirror of doctor's vitals screen for self-view. Same chart visuals. |
| `lib/screens/patient/doctor_chat_screen.dart`                     | Companion to `patient_chat_screen.dart`; same chat models. |
| `lib/features/ai_assessment/screens/*` (welcome, flow, review, loading, result) | Produces `AiConsultResponse` records the doctor reads via report history. |

The doctor web app does NOT implement any of these.

---

## D. Recommended web component library structure

```
src/components/
  ui/
    Avatar.tsx
    Badge.tsx
    Button.tsx          // CustomButton + variants
    Card.tsx
    Chip.tsx
    Dialog.tsx
    Divider.tsx
    EmptyState.tsx
    GradientButton.tsx
    IconButton.tsx
    Input.tsx           // form field with prefix icon
    PasswordInput.tsx
    Pill.tsx
    SectionTitle.tsx
    Select.tsx
    SkeletonList.tsx
    SkeletonDashboard.tsx
    StatusBadge.tsx
    Toast.tsx
    Tabs.tsx
    Tooltip.tsx
  layout/
    Sidebar.tsx
    Topbar.tsx
    DecoratedBackground.tsx
  feedback/
    NoInternetView.tsx
    ServerDownView.tsx
  patient/
    PatientCard.tsx
    AssignPatientDialog.tsx
    PatientBioChip.tsx
    PatientInfoCard.tsx
  vitals/
    VitalCard.tsx
    VitalLiveCard.tsx        // HR/SpO2/Battery hero cards
    VitalChart.tsx
    PeriodSelector.tsx
    StatsSummary.tsx
    ConnectionBanner.tsx
  chat/
    ChatTile.tsx
    MessageBubble.tsx
    DateSeparator.tsx
    ChatInput.tsx
  appointments/
    AppointmentCard.tsx
    GroupedHeader.tsx
  notifications/
    NotificationTile.tsx
  dashboard/
    StatCard.tsx
    AlertCard.tsx
    StatusCard.tsx
```

Each component should accept a single `className` override so colors/
spacing can be tweaked at call sites without re-implementing variants.
