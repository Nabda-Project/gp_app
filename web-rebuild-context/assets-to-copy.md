# assets-to-copy.md — Static Assets for the Doctor Web App

> What was copied from the Flutter project into
> `web-rebuild-context/assets/`, where to use each file in the web
> rebuild, and what's **deliberately not** copied.

The Flutter doctor app is unusually asset-light: every "illustration"
is a procedural `CustomPaint`, all icons are Material Icons rendered
from Flutter's built-in font, and there are no Lottie animations.

This document covers:
1. **Assets copied** (what's now under `/assets/…`).
2. **Where each one is used** in the doctor flow.
3. **React/Next.js usage notes** for each.
4. **Assets NOT copied** (and why).
5. **Missing assets** (referenced in code but not present anywhere).

---

## 0. Folder layout

```
web-rebuild-context/
└── assets/
    ├── logos/                              ← REAL brand asset + 3 SVGs
    │   ├── app-logo.png                    (1254×1254 RGBA — master)
    │   ├── app-logo-1024.png               (1024×1024 — iOS export, useful for favicon gen)
    │   ├── nabda-logo.svg                  (200×200 ECG-in-circle, drop-in replacement for AppLogo)
    │   ├── nabda-logo-mark.svg             (bare ECG mark — no circle, uses currentColor)
    │   └── nabda-logo-animated.svg         (self-drawing variant for the splash)
    ├── launcher-icons-reference/           ← REFERENCE only — generated mipmaps
    │   ├── ic_launcher-mdpi-48.png
    │   ├── ic_launcher-hdpi-72.png
    │   ├── ic_launcher-xhdpi-96.png
    │   ├── ic_launcher-xxhdpi-144.png
    │   └── ic_launcher-xxxhdpi-192.png
    ├── icons/                              ← intentionally empty (README inside)
    │   └── README.md
    ├── images/                             ← intentionally empty (README inside)
    │   └── README.md
    ├── fonts/                              ← intentionally empty (README inside)
    │   └── README.md
    └── animations/                         ← intentionally empty (README inside)
        └── README.md
```

---

## 1. Copied assets

### 1.1 `assets/logos/app-logo.png`

| Property | Value |
|----------|-------|
| **Original Flutter path** | `E:/side projects/gp_app/app-logo.png` |
| **Copied to** | `web-rebuild-context/assets/logos/app-logo.png` |
| **Type / size** | PNG, 1254×1254, 8-bit RGBA, ~917 KB |
| **Where used in Flutter** | Drives `flutter_launcher_icons` (configured in `pubspec.yaml:54-58`). Generates Android mipmaps, iOS `AppIcon.appiconset`, and macOS `app_icon_*`. **Not referenced anywhere in `lib/`.** |
| **Required for doctor web app?** | ✅ Yes — this is the **single canonical brand image** and must drive every web PWA / favicon export. |
| **React / Next.js usage** | Place in `public/brand/app-logo.png`. Generate the full favicon set with [`favicon.io`](https://favicon.io/favicon-converter/) or `realfavicongenerator.net`. Recommended sizes: `16, 32, 48, 96, 192, 256, 512` PNG + a `favicon.ico` containing 16/32/48. In `<head>`:<br>`<link rel="icon" type="image/png" sizes="32x32" href="/favicons/favicon-32.png">`<br>`<link rel="icon" type="image/png" sizes="192x192" href="/favicons/favicon-192.png">`<br>`<link rel="apple-touch-icon" sizes="180x180" href="/favicons/apple-touch-icon.png">`<br>Add the PWA icons to `public/manifest.json` (use `#F8FAFC` bg + `#407BFF` theme — do NOT inherit the Flutter default `#0175C2`). |

### 1.2 `assets/logos/app-logo-1024.png`

| Property | Value |
|----------|-------|
| **Original Flutter path** | `E:/side projects/gp_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` |
| **Copied to** | `web-rebuild-context/assets/logos/app-logo-1024.png` |
| **Type / size** | PNG, 1024×1024, 8-bit RGBA, ~475 KB |
| **Where used in Flutter** | iOS App Store icon (rendered from `app-logo.png`). |
| **Required for doctor web app?** | ⚠️ Optional — only useful as a pre-flattened RGB asset if `app-logo.png`'s transparency channel causes issues with a favicon generator. Prefer `app-logo.png`. |
| **React / Next.js usage** | Same role as `app-logo.png`. Pick one. |

### 1.3 `assets/logos/nabda-logo.svg` (new — re-authored from `app_logo.dart`)

| Property | Value |
|----------|-------|
| **Original Flutter source** | `lib/widgets/reusable/app_logo.dart` (procedural `_HeartbeatPainter`) |
| **Copied to** | `web-rebuild-context/assets/logos/nabda-logo.svg` |
| **Type / size** | SVG, 200×200 viewBox, ~5 KB |
| **Where used in Flutter** | The `AppLogo` widget renders this exact ECG curve on the **splash screen** (`splash_screen.dart:439`) and the **auth screen** (`auth_screen.dart:480`). |
| **Construction details** | 121 interpolated points produced by replaying the Flutter painter's smooth-step (`localT² · (3-2·localT)`) interpolation across the 13 waypoints at `app_logo.dart:117-131`. ViewBox is 200×200 to match the splash logo's nominal size; scale freely (SVG is resolution-independent). Two stacked paths: a 12 px-wide blurred glow (`stroke-opacity: 0.3`, Gaussian-blur 4) underneath a 6 px-wide sharp stroke. The white circle backplate uses a primary-blue 20%-alpha drop shadow that mirrors `0 10 20 primaryBlue × 20%` from the Flutter widget. |
| **Required for doctor web app?** | ✅ Yes — this is the canonical **in-app brand mark** for the web. Use everywhere `AppLogo` appears in mobile. |
| **React / Next.js usage** | Save next to your React components or in `public/brand/nabda-logo.svg`. Two equally good options:<br>**(a)** Inline import via SVGR: `import NabdaLogo from '~/assets/logos/nabda-logo.svg';` then `<NabdaLogo width={120} height={120} />`.<br>**(b)** Static URL: `<img src="/brand/nabda-logo.svg" alt="NABDA" width={120} height={120} />`.<br>For Next.js App Router: `next.config.js` with `@svgr/webpack` loader if you want option (a). |

### 1.4 `assets/logos/nabda-logo-mark.svg` (new)

| Property | Value |
|----------|-------|
| **Original Flutter source** | Same painter (`app_logo.dart`) but with the white circle backplate removed. |
| **Copied to** | `web-rebuild-context/assets/logos/nabda-logo-mark.svg` |
| **Type / size** | SVG, 200×200 viewBox, ~1.2 KB |
| **Where used in Flutter** | n/a (Flutter always renders the circle backplate). |
| **Required for doctor web app?** | ✅ Yes — useful any time you need the ECG line **without** the white circle (header pills, in-text decoration). |
| **Stroke color** | `currentColor` — recolor with CSS `color`. |
| **React / Next.js usage** | `<NabdaMark className="text-primary h-6 w-6" />`. The bare path uses `stroke="currentColor"`, so the surrounding `color` CSS controls it. |

### 1.5 `assets/logos/nabda-logo-animated.svg` (new)

| Property | Value |
|----------|-------|
| **Original Flutter source** | `splash_screen.dart` `_ecgDrawAnimation` (1.8 s easeInOut loop) combined with `app_logo.dart`'s draw-in trim. |
| **Copied to** | `web-rebuild-context/assets/logos/nabda-logo-animated.svg` |
| **Type / size** | SVG with embedded SMIL `<animate>` elements, ~2.5 KB |
| **Required for doctor web app?** | ⚠️ Optional — use on the splash route to replicate the mobile draw-in. Static `nabda-logo.svg` is also fine. |
| **React / Next.js usage** | Drop-in `<img src="/brand/nabda-logo-animated.svg" alt="NABDA loading" />`. The animation runs natively in the browser without JS. If SMIL is dropped from a future browser version, swap to a CSS `@keyframes` driving `stroke-dashoffset` on the inline SVG. |

### 1.6 `assets/launcher-icons-reference/ic_launcher-*.png`

| Property | Value |
|----------|-------|
| **Original Flutter path** | `android/app/src/main/res/mipmap-{m,h,x,xx,xxx}dpi/ic_launcher.png` |
| **Copied to** | `web-rebuild-context/assets/launcher-icons-reference/` |
| **Sizes** | 48, 72, 96, 144, 192 |
| **Where used in Flutter** | Android launcher icon (system tray), also used as the notification small icon via `@mipmap/ic_launcher` in `health_monitor_service.dart:297, 644` and `push_notification_service.dart:144`. |
| **Required for doctor web app?** | ❌ No — strictly **reference**. They were generated from `app-logo.png` and are LOWER resolution than the source. Always regenerate from the master `app-logo.png` for the web. |
| **React / Next.js usage** | Use these only to verify your generated favicons match the mobile look. Delete from `public/` once verified. |

---

## 2. Assets NOT copied (and why)

### 2.1 Default Flutter web PWA icons

| File | Why not |
|------|---------|
| `web/favicon.png` (16×16) | Flutter's default blue "F" icon — NOT branded as NABDA. |
| `web/icons/Icon-192.png` | Same default Flutter icon. |
| `web/icons/Icon-512.png` | Same default Flutter icon. |
| `web/icons/Icon-maskable-192.png` | Same default. |
| `web/icons/Icon-maskable-512.png` | Same default. |
| `web/manifest.json` | Theme colors are Flutter defaults (`#0175C2`), NOT NABDA brand (`#407BFF`). |

**Action:** ⚠️ Do not copy. Regenerate the entire web icon set from
`assets/logos/app-logo.png` and write a new `manifest.json`:

```json
{
  "name": "NABDA — Doctor",
  "short_name": "NABDA",
  "description": "NABDA — Doctor portal",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#F8FAFC",
  "theme_color":      "#407BFF",
  "icons": [
    { "src": "/favicons/icon-192.png",         "sizes": "192x192", "type": "image/png" },
    { "src": "/favicons/icon-512.png",         "sizes": "512x512", "type": "image/png" },
    { "src": "/favicons/icon-maskable-192.png","sizes": "192x192", "type": "image/png", "purpose": "maskable" },
    { "src": "/favicons/icon-maskable-512.png","sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

### 2.2 iOS / macOS / Windows icon variants

| Source | Why not |
|--------|---------|
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` (29 files) | All generated from `app-logo.png`. Only `Icon-App-1024x1024@1x.png` was copied as a fallback. |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png` | Three 1×1 placeholder PNGs. Useless. |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png` | Generated from `app-logo.png`. |
| `windows/runner/resources/app_icon.ico` | Windows launcher icon. n/a for web. |

### 2.3 Patient-only assets

There are no patient-only image assets to skip — the **entire** asset
surface area is `app-logo.png` and Flutter-generated derivatives.
Patient-only mobile screens (dashboard, vitals self-view, chatbot, AI
assessment flow) all use the same `AppLogo` + Material Icons + `AppColors`
palette as the doctor screens.

### 2.4 Procedural visuals (no asset to copy)

The following look like "assets" in the rendered app but exist purely
in code — they have already been documented for re-implementation in
DESIGN_SYSTEM.md and COMPONENT_INVENTORY.md:

| What | Where in code | Web treatment |
|------|---------------|---------------|
| Doctor dashboard hero gradient + 2 white circles | `doctor_dashboard_screen.dart:665-833` | CSS `bg-gradient-to-br from-[#407BFF] to-[#00B4D8]` + 2 absolutely-positioned `rounded-full` divs |
| Profile hero (280-px gradient) | `profile_screen.dart:550-731` | Same gradient pattern |
| Decorative page background circles | `decorated_background.dart` | 3 absolutely-positioned circles via `::before`, `::after`, child div (see DESIGN_SYSTEM.md §3.7) |
| Pulse rings (splash, server-down, no-internet) | `splash_screen.dart`, `server_down_view.dart`, `no_internet_view.dart` | CSS `@keyframes` translating `scale()` + `opacity()` |
| Heartbeat lub-dub scale (splash logo) | `splash_screen.dart:60-79` | 5-stage CSS keyframes timed at 1.2 s |
| ECG background scrolling line (splash) | `splash_screen.dart:494-572` | Optional. Same `<path>` + animate `stroke-dashoffset` |
| StatCard sin animated circles + ghost icon | `stat_card.dart:172-198` | Skip (delight feature) |
| StatusCard pulsing glow | `status_card.dart:188-233` | CSS `@keyframes` on `box-shadow` |
| VitalCard backgrounds (HR wave, bubbles, charging wave) | `vital_card.dart:204-567` | Skip for v1 (delight feature) |
| Shimmer skeletons | `shimmer` package in `dashboard_skeleton.dart`, `list_skeleton.dart`, `user_avatar.dart` | CSS linear-gradient sweep (recipe in `/assets/animations/README.md`) |
| Chart range-area + line | `patient_vitals_screen.dart` via `syncfusion_flutter_charts` | `recharts` `ComposedChart` with `<Area>` + `<Line>` (see WEB_IMPLEMENTATION_PLAN.md §3) |

---

## 3. Missing assets (referenced but not present)

These paths are declared in source code but the files do **not exist**
anywhere in the repository:

### 3.1 `AppAssets` placeholder paths

| Constant name      | Declared path                         | Source                                 | Status |
|--------------------|---------------------------------------|----------------------------------------|--------|
| `AppAssets.logo`   | `assets/images/logo.png`              | `lib/utils/constants.dart:49`          | ❌ never created — `AppAssets` constants are also unused in `lib/` |
| `AppAssets.doctorIcon`     | `assets/icons/doctor.png`     | `lib/utils/constants.dart:50`          | ❌ never created — unused |
| `AppAssets.patientIcon`    | `assets/icons/patient.png`    | `lib/utils/constants.dart:51`          | ❌ never created — unused |
| `AppAssets.onboardingImage`| `assets/images/onboarding.png`| `lib/utils/constants.dart:52`          | ❌ never created — unused |

> **Confirmation:** `pubspec.yaml` does not contain a
> `flutter.assets:` block, so even if these files existed they wouldn't
> be bundled. They are dead constants left over from scaffolding.
> Ignore for the web rebuild.

### 3.2 Network-loaded image (the Google "G" logo)

| Source                                | What                                | Notes |
|---------------------------------------|-------------------------------------|-------|
| `lib/screens/auth/auth_screen.dart:833-851` | Loads Wikipedia's `Google_"G"_logo.svg.png` at runtime, with a `google.com/favicon.ico` fallback. | The web app should NOT hot-link Wikipedia. Replace with an SVG embedded inline (no Sign-in-with-Google flow is required in the v1 web app — see AUTH_AND_SESSION.md). |

### 3.3 Cairo TTF (referenced via `fontFamily: 'Cairo'` but not bundled)

| Where referenced                                                       | Resolution on mobile                                |
|------------------------------------------------------------------------|-----------------------------------------------------|
| `lib/screens/doctor/patient_detail_screen.dart:272`                    | OS-level Cairo or silent fall-back.                  |
| `lib/features/ai_assessment/screens/report_history_screen.dart:123-128, 208-209, 219-221, 240-243, 273-274, 281-283` | OS-level Cairo or silent fall-back. |

> **Web action:** load Cairo explicitly from Google Fonts (see
> `/assets/fonts/README.md`). Do not bundle TTF files in the web app —
> let the browser cache Google Fonts.

---

## 4. Doctor-web-app integration checklist

After copying `web-rebuild-context/assets/` into your web project:

- [ ] Move `assets/logos/app-logo.png` → `public/brand/app-logo.png`.
- [ ] Generate favicons from `app-logo.png` (16/32/48/96/192/256/512 + ICO).
- [ ] Move `assets/logos/nabda-logo.svg` → `public/brand/nabda-logo.svg`
      (or import via SVGR).
- [ ] Move `assets/logos/nabda-logo-mark.svg` → `public/brand/nabda-mark.svg`.
- [ ] Use `nabda-logo-animated.svg` on the splash/loading route.
- [ ] Write a new `manifest.json` with `theme_color: #407BFF`,
      `background_color: #F8FAFC`.
- [ ] Add Google Fonts `<link>` for Roboto + Cairo (see
      `/assets/fonts/README.md`).
- [ ] Add Material Symbols Rounded webfont (see `/assets/icons/README.md`).
- [ ] Keep `assets/launcher-icons-reference/` for visual diff during QA;
      delete before deploying to production.
- [ ] Do NOT bundle Lottie / images / TTFs — there are none to bundle.
- [ ] Do NOT carry over `web/manifest.json` or `web/icons/*` from
      Flutter — they are unbranded defaults.

---

## 5. Summary

| Category               | Copied? | Files                                                            |
|------------------------|---------|------------------------------------------------------------------|
| Brand logo (raster)    | ✅      | `assets/logos/app-logo.png`, `app-logo-1024.png`                  |
| Brand logo (vector)    | ✅      | `assets/logos/nabda-logo.svg`, `nabda-logo-mark.svg`, `nabda-logo-animated.svg` (re-authored from `lib/widgets/reusable/app_logo.dart`) |
| Launcher icon refs     | ✅ (reference only) | `assets/launcher-icons-reference/*.png`               |
| Custom icons           | ❌      | none — Flutter relies on Material Icons font                      |
| Illustrations / hero images | ❌ | none — the design is procedural                                  |
| Fonts                  | ❌      | none — load from Google Fonts                                     |
| Lottie / animation files | ❌    | none — animations are pure code                                   |
| Patient-only assets    | n/a    | the project has no patient-only assets                            |

The doctor web app needs effectively two real assets: the master
`app-logo.png` (for favicon/PWA generation) and the re-authored
`nabda-logo.svg` (for in-app brand). Everything else is procedural,
icon-font based, or CSS-driven.
