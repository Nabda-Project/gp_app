# ASSET_MANIFEST.md — Static Assets Inventory

> Exhaustive list of every visual asset the Flutter app ships (or
> references), where it's used, and the recommended treatment in the
> doctor web app. The mobile app is unusually asset-light: almost all
> imagery is procedurally drawn via `CustomPaint`, and the only raster
> assets are the launcher icon and the Flutter-generated PWA icons.

---

## 1. Raster assets that physically exist in the repo

### 1.1 `app-logo.png`

- **Path:** `app-logo.png` (project root, 917 KB).
- **Origin:** declared in `pubspec.yaml:54-58`:
  ```yaml
  flutter_launcher_icons:
    android: true
    ios: true
    image_path: "app-logo.png"
    min_sdk_android: 21
  ```
- **Used by:** The `flutter_launcher_icons` tool generates Android +
  iOS launcher icons from this image. It is **not** referenced anywhere
  in `lib/` and is **not** registered under `flutter.assets:` in
  `pubspec.yaml`.
- **Doctor web app:** copy to `public/app-logo.png` and use it as the
  favicon source. Generate `32×32`, `48×48`, `192×192`, `512×512` PWA
  icons from it.

### 1.2 Android launcher icons (`mipmap-*`)

Files (generated from `app-logo.png`):

| Path                                                          |
|---------------------------------------------------------------|
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`        |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`        |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`       |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`      |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`     |

- **Used by:** Android launcher only. Referenced from
  `health_monitor_service.dart:297, 644` and `push_notification_service.dart:144`
  as the notification small icon (`@mipmap/ic_launcher`).
- **Doctor web app:** not needed (web has its own icon set in `web/icons/`).

### 1.3 Android splash background

- **Path:** `android/app/src/main/res/drawable/launch_background.xml`.
- **Content:** a single white solid-color drawable (the actual visual
  splash is the Flutter `SplashScreen` widget, not this file).
- **Doctor web app:** not needed. The web splash equivalent is the
  in-app `SplashScreen` route or a quick CSS gradient backdrop.

### 1.4 Flutter web PWA icons

Files under `web/icons/`:

| Path                                  | Size | Purpose       |
|---------------------------------------|------|---------------|
| `web/icons/Icon-192.png`              | 192² | PWA           |
| `web/icons/Icon-512.png`              | 512² | PWA           |
| `web/icons/Icon-maskable-192.png`     | 192² | PWA maskable  |
| `web/icons/Icon-maskable-512.png`     | 512² | PWA maskable  |
| `web/favicon.png`                     | n/a  | Browser tab   |

- **Note ⚠️:** these are the **default Flutter web placeholder icons**
  (blue Flutter "F" gradient), not branded with NABDA. The
  `web/manifest.json` `background_color` and `theme_color` are also the
  Flutter default (`#0175C2`), NOT the NABDA primary blue (`#407BFF`).
- **Doctor web app:** **DO NOT** copy these. Generate new icons from
  `app-logo.png` and use `#407BFF` as `theme_color`, `#F8FAFC` as
  `background_color`.

### 1.5 `web/manifest.json` content (for reference)

```json
{
  "name": "NABDA",
  "short_name": "NABDA",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#0175C2",  // Flutter default — REPLACE with #F8FAFC
  "theme_color":      "#0175C2",  // Flutter default — REPLACE with #407BFF
  "description": "NABDA - Your Health, Your Pulse",
  "orientation": "portrait-primary",  // tablet/desktop should drop this
  "prefer_related_applications": false,
  "icons": [ … ]
}
```

For the doctor web app:
```json
{
  "name": "NABDA Doctor",
  "short_name": "NABDA",
  "description": "NABDA — Doctor portal",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#F8FAFC",
  "theme_color": "#407BFF",
  "icons": [ /* generated from app-logo.png */ ]
}
```

---

## 2. Placeholder assets DECLARED but NOT shipped

`lib/utils/constants.dart:47-53`:

```dart
class AppAssets {
  static const String logo = "assets/images/logo.png";
  static const String doctorIcon = "assets/icons/doctor.png";
  static const String patientIcon = "assets/icons/patient.png";
  static const String onboardingImage = "assets/images/onboarding.png";
}
```

These paths point to files that **do not exist in the repo**, and
`pubspec.yaml` does NOT register any `flutter.assets:` block. They are
unused placeholders.

- **Doctor web app:** ignore entirely. Do not implement any of them.

---

## 3. Network images (loaded at runtime, not bundled)

### 3.1 Google "G" logo (auth screen)

- **Source:** `lib/screens/auth/auth_screen.dart:833-851`.
- **URL:** `https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png`
- **Fallback URL:** `https://www.google.com/favicon.ico`
- **Final fallback icon:** `Icons.g_mobiledata` (Material).
- **Web equivalent:** use an inline SVG from
  `@react-icons/all-files/fc/FcGoogle` (or similar). Avoid external
  Wikipedia hot-linking on the web.

### 3.2 Cached patient profile images

- **Loaded via:** `cached_network_image` package, used inside
  `UserAvatar` (`lib/widgets/reusable/user_avatar.dart:80-89`).
- **Source URLs:** backend-provided `profileImageUrl` field on
  `UserModel`, `PatientResponseModel`, `DoctorInfoModel`,
  `ChatContactModel`. May be:
  - HTTP(S) URLs.
  - Base64 data URIs (`data:image/jpeg;base64,…`) — used when the user
    uploaded a photo via the profile screen.
  - Local file paths (Android cache, not relevant on web).
- **Web equivalent:** standard `<img>` element with `loading="lazy"`,
  `onError` swapping to the initial-letter fallback.

### 3.3 No other network images

A grep of `lib/` for `Image.network`, `Image.asset`, `AssetImage`, and
`Lottie` confirms there are no other bundled or downloaded images
beyond the two cases above.

---

## 4. Procedurally drawn imagery (CustomPaint)

The mobile UI's "look" is dominated by `CustomPaint` widgets — no
raster assets are involved. Each is portable to inline SVG or `<canvas>`
on the web.

### 4.1 NABDA logo (ECG line in a circle)

- **Source:** `lib/widgets/reusable/app_logo.dart` (entire file).
- **Description:** white circle, primaryBlue ECG path with a soft blur
  glow. Strokes: main = `size × 0.03` width; glow = `size × 0.06` width
  + `MaskFilter.blur(BlurStyle.normal, 4)`.
- **Path waypoints (normalized fraction X, fraction Y — `:117-131`):**

```
(0.00, 0.00) baseline start
(0.15, 0.00) flat
(0.20, 0.08) small P-wave up
(0.25, 0.00)
(0.32, 0.00) flat before QRS
(0.36, 0.15) Q dip
(0.42, -1.00) R spike (big up)
(0.48, 0.40) S dip
(0.52, 0.00)
(0.58, 0.00)
(0.65, -0.15) T wave bump
(0.72, 0.00)
(1.00, 0.00) baseline end
```

Y is amplitude-normalized to `-1=full up, +1=full down`, scaled by
`amplitude = h × 0.30`. Path is interpolated with 120 segments using
smooth-step `t*t*(3-2t)`. See `:133-159` for the interpolation.

When `animate=true` + `animation` is provided, the path is trimmed to
`progress * total_points`. Draw with `stroke-dasharray` + animated
`stroke-dashoffset` on web.

### 4.2 Splash background ECG (`_BackgroundEcgPainter`)

- **Source:** `lib/screens/splash/splash_screen.dart:494-572`.
- Faint white (`× 6% alpha`) PQRST line drawn across the splash
  background, scrolling at 1.8 s loop.
- **Doctor web app:** not needed (the web splash is brief and the
  doctor likely never sees an animated splash).

### 4.3 StatCard background painter

- **Source:** `lib/widgets/reusable/stat_card.dart:172-198`.
- Three drifting `RadialGradient` circles with very low opacity
  (0.02–0.05) animated by a 3-s sin loop. Plus a 70-px background icon
  with sin-pulsing opacity (0.03–0.06).
- **Web:** skip the painter; use a static `box-shadow` and a single
  background icon in `opacity: 0.04`.

### 4.4 StatusCard background painter

- **Source:** `lib/widgets/reusable/status_card.dart:188-233`.
- Healthy: a moving `RadialGradient` highlight sweeping from left to right.
- Warning/Critical: 3 concentric pulsing rings near the right edge.
- Unknown: no painter.
- **Web:** CSS `@keyframes` translating a `radial-gradient` left → right
  is enough for the healthy state; rings via `box-shadow` pulses for
  warning/critical.

### 4.5 VitalCard painters

- **Source:** `lib/widgets/reusable/vital_card.dart`.
- Heart-rate ECG (`_HeartbeatPainter`, `:233-338`): scrolling realistic
  PQRST line.
- Bubbles (`_BubblesPainter`, `:369-417`): 7 bubbles rising with
  per-bubble `delay`.
- Charging wave (`_ChargingWavePainter`, `:458-503`): two sine-wave fills
  proportional to battery percentage.
- Soft pulse (`_SoftPulsePainter`, `:535-567`): 3 concentric circles
  scaling 0 → max and fading.
- **Web (recommended):** skip per-card painted backgrounds — they're a
  delight feature, not a brand requirement. The colored icon container
  + value + label is enough for parity.

### 4.6 Splash pulse rings

- **Source:** `splash_screen.dart:382-426`.
- 2 layered rings around the central logo, scale 1 → 1.8 over 1.8 s,
  opacity 0.4 → 0.
- **Web port:**

```css
@keyframes nabda-pulse-ring {
  0%   { transform: scale(1);   opacity: 0.4; }
  100% { transform: scale(1.8); opacity: 0;  }
}
.pulse-ring  { animation: nabda-pulse-ring 1.8s ease-out infinite; }
.pulse-ring--offset { animation-delay: 0.9s; }
```

### 4.7 Server-down ripple rings

- **Source:** `server_down_view.dart:108-131`.
- 3 rings, scale 1 → 2.5 over 3 s, opacity 1 → 0, 0.33 s stagger.
- **Web:** same CSS pattern with 3 delayed copies.

### 4.8 Shimmer skeletons

- **Library:** `shimmer` package (`pubspec.yaml:31`).
- **Used in:** `DashboardSkeleton`, `ListSkeleton`, `UserAvatar`
  network-image placeholder.
- **Base colors:** `grey[300] → grey[100]` (dashboard, avatar) or
  `grey[200] → grey[50]` (list).
- **Web port:** Tailwind `animate-pulse` works for the simple case, or
  use a linear-gradient sweep:

```css
@keyframes shimmer {
  0%   { background-position: -200% 0; }
  100% { background-position: 200% 0;  }
}
.shimmer {
  background: linear-gradient(90deg, #E5E7EB 0%, #F9FAFB 50%, #E5E7EB 100%);
  background-size: 200% 100%;
  animation: shimmer 1.5s linear infinite;
}
```

### 4.9 Charts (Syncfusion)

- **Library:** `syncfusion_flutter_charts` (`pubspec.yaml:38`).
- **Used in:** `patient_vitals_screen.dart:720-836`.
- **Charts:** `SfCartesianChart` with a `RangeAreaSeries` (min/max
  band, color × 12%) + a `LineSeries` (avg, width 2.5, circle marker
  6×6 white-bordered).
- **Web equivalent:** `recharts`, `chart.js + react-chartjs-2`, or
  `apexcharts`. recharts has `ComposedChart` with `<Area>` + `<Line>`
  that maps 1:1.

### 4.10 FL_chart (declared but unused in doctor screens)

- **Library:** `fl_chart` (`pubspec.yaml:36`).
- Searched: not used in any doctor screen. Likely used elsewhere
  (patient dashboard) but not relevant to the doctor web app.

---

## 5. Fonts

### 5.1 Roboto (default)

- **Declared at:** `lib/theme/app_theme.dart:9` (`fontFamily: 'Roboto'`).
- **Source:** Flutter bundles Roboto on Android by default; **NOT in the
  repo as a TTF**. iOS / web build would need to load it explicitly.
- **Weights used in code:** 400 (regular), 500 (`w500`), 600 (`w600`),
  700 (`bold`), 800 (`w800`).
- **Web action:** load Roboto from Google Fonts (weights 400, 500, 600,
  700, 800; latin + latin-ext).

### 5.2 Cairo (Arabic-heavy contexts)

- **Declared per-widget**, e.g.
  - `lib/screens/doctor/patient_detail_screen.dart:272`
    (`fontFamily: 'Cairo'` on the "عرض تقارير التقييم" button).
  - `lib/features/ai_assessment/screens/report_history_screen.dart:123-128, 208-209, 219-221, 240-243, 273-274, 281-283`.
- **Source:** **NOT bundled as a TTF in the repo.** The mobile app
  appears to rely on the OS to supply Cairo. If the OS lacks it, Flutter
  silently falls back to the system default.
- **Web action:** explicitly load Cairo from Google Fonts (weights 400,
  500, 600, 700, 800). Apply to `[lang='ar']` blocks and the doctor's
  AI report history page.

### 5.3 Other fonts

- `font_awesome_flutter` (`pubspec.yaml:16`) is in dependencies but no
  doctor screen uses `FontAwesomeIcons` directly. (A grep confirms it
  isn't imported in any `lib/screens/doctor/` file.) Web app does NOT
  need FontAwesome.

---

## 6. Animations & lottie

- **No Lottie files.** A grep for `lottie` / `Lottie` returns zero
  matches in `lib/`. No JSON animation assets exist anywhere.
- **Animations** are all implemented as Flutter `AnimationController`s
  driving `Transform`, `Opacity`, `CustomPaint`, or `ScaleTransition`.
  Web equivalents are CSS keyframes or framer-motion.

---

## 7. Sounds

- **Local notifications** (Android) trigger the default Android
  notification tone (`playSound: true` in
  `push_notification_service.dart:103-110` and
  `health_monitor_service.dart:113-117`).
- **Critical alerts** also use the default tone + vibration.
- **In-app toast heads-up:** `SystemSound.play(SystemSoundType.alert)`
  + `HapticFeedback.mediumImpact()` (`notification_service.dart:44-47`).
- **Web equivalent:** no audio is bundled. The web app may stay silent
  (recommended) or use a small `<audio>` chime for new chat messages
  when the user opts in. No assets are required.

---

## 8. Material Icons

Mobile uses the built-in Flutter `Icons.*` constants. All icons are
rendered procedurally by the Material Icons font that Flutter ships.

- **Web equivalent:** `Material Symbols Rounded` web font via Google
  Fonts, OR `@mui/icons-material` package. Use the rounded variants.
- **Complete list of icons used:** see DESIGN_SYSTEM.md §6.

---

## 9. SVGs

The repo contains **no SVG files**. All "logo / decorative" SVG-like
content is drawn with `CustomPaint`. The web app should re-author the
following inline SVGs:

| SVG to author              | Reference                                                                  |
|----------------------------|----------------------------------------------------------------------------|
| NABDA ECG logo            | `app_logo.dart` (`_HeartbeatPainter`)                                       |
| Splash decorative ECG     | `splash_screen.dart` (`_BackgroundEcgPainter`) — optional                   |
| Vital-card ECG wave       | `vital_card.dart` (`_HeartbeatPainter`) — optional                          |

---

## 10. Backend-hosted images

The only "remote images" the app fetches are user profile photos via
the `profileImageUrl` field on every user-like DTO. They may be:
- A real URL (CDN/blob storage).
- A base64 data URI.

The backend currently accepts and stores base64 data URIs (seen by the
profile screen uploading `data:image/jpeg;base64,…` via `PUT /user/me`,
`profile_screen.dart:84-89`).

No other backend-hosted images are referenced.

---

## 11. Web action checklist

- [ ] Copy `app-logo.png` to `public/app-logo.png`.
- [ ] Generate web favicons (16, 32, 48 px ICO and 192/512 PNGs from the
      source).
- [ ] Create `public/manifest.json` with NABDA brand colors
      (`#F8FAFC` bg, `#407BFF` theme).
- [ ] Load Google Fonts: Roboto (400/500/600/700/800) and Cairo
      (400/500/600/700/800).
- [ ] Load Material Symbols Rounded (or install `@mui/icons-material`).
- [ ] Author inline SVG for the NABDA ECG logo (use waypoints in §4.1).
- [ ] CSS keyframes for pulse rings (splash, server-down) — see §4.6, §4.7.
- [ ] Shimmer keyframes (§4.8) for skeleton placeholders.
- [ ] Pick a charts library (recommended `recharts`) and recreate the
      vitals chart (§4.9).
- [ ] Do NOT bundle FontAwesome.
- [ ] Do NOT use the Wikipedia Google "G" image — use a packaged SVG.
- [ ] Do NOT implement `assets/images/logo.png` etc. (placeholders).
- [ ] Skip Lottie / audio.

---

## 12. Summary

The doctor web app needs effectively **zero pre-existing image
assets**. Brand identity is achieved via:

1. The procedural NABDA ECG logo (re-authored as SVG).
2. Brand colors and gradients (see DESIGN_SYSTEM.md).
3. Material icons (web fonts).
4. Roboto + Cairo (Google Fonts).
5. CSS keyframe animations.
6. A favicon generated from `app-logo.png`.

This makes the asset surface area trivially small and the doctor web
app fully self-contained.
