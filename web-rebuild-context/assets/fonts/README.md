# /assets/fonts — intentionally empty

The Flutter project ships **no TTF/OTF/WOFF font files**.

The mobile app uses:

- **Roboto** — Flutter's default OS-provided font on Android. iOS would
  silently fall back to the system font (San Francisco). Declared at
  `lib/theme/app_theme.dart:9` as `fontFamily: 'Roboto'`.
- **Cairo** — referenced inline for Arabic strings (e.g.
  `lib/screens/doctor/patient_detail_screen.dart:272`,
  `lib/features/ai_assessment/screens/report_history_screen.dart:123`),
  but **NOT bundled**. The mobile app relies on the OS / Material font
  resolution to find Cairo; if absent it falls back silently.

## For the web rebuild — load from Google Fonts

Add this to `<head>` (Next.js: in `_document.tsx` or use `next/font`):

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link
  href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;500;700&family=Cairo:wght@400;500;600;700;800&display=swap"
  rel="stylesheet"
/>
```

CSS:

```css
:root {
  --font-sans:   'Roboto', 'Cairo', system-ui, -apple-system, 'Segoe UI', sans-serif;
  --font-arabic: 'Cairo', 'Roboto', system-ui, sans-serif;
}
html[lang="ar"] { font-family: var(--font-arabic); direction: rtl; }
```

**Weights used in code (from a sweep of every doctor screen):**
- Roboto: 400, 500, 600, 700, 800.
- Cairo: 400, 500, 600, 700, 800.
