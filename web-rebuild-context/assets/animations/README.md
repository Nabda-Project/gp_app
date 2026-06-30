# /assets/animations — intentionally empty

The Flutter doctor app uses **NO Lottie / Rive / GIF / animated SVG
files**. Every motion in the UI is produced by Flutter's
`AnimationController` driving:

- `Transform.scale` / `Transform.translate`
- `Opacity` / `FadeTransition`
- `SlideTransition`
- `CustomPaint` repaints

For the web equivalents see DESIGN_SYSTEM.md §3.10 ("Common animation
durations") and ASSET_MANIFEST.md §4 ("Procedurally drawn imagery").

The most important motions to re-implement (with CSS / framer-motion):

| Animation                       | Where seen           | Web recipe |
|---------------------------------|----------------------|------------|
| Splash ECG draw-in (1.8 s loop) | `/login` redirect    | `stroke-dasharray` + animated `stroke-dashoffset` on the SVG path (see `/assets/logos/nabda-logo-animated.svg`) |
| Heartbeat scale (1.2 s lub-dub) | Splash logo          | CSS keyframes with 5-stage scale tween |
| Pulse rings (1.8 s)             | Splash, server-down  | Two `::before` / `::after` rings, scale 1 → 1.8, opacity 0.4 → 0 |
| Ripple rings (3 s, 3 copies)    | Server-down icon     | Three `<div>` rings with staggered animation-delay |
| Shimmer skeleton                | List/dashboard load  | Linear-gradient sweep (200% wide) at `bg-position: -200% 0` → `200% 0` |
| Toast slide-in (0.6 s elastic)  | Snackbars            | Spring physics via framer-motion or CSS cubic-bezier overshoot |
| Fade-slide entrance (0.5 s)     | Many screen sections | `@keyframes fade-up { from { opacity:0; transform: translateY(12px) } }` |
| Staggered list reveal           | Card lists           | CSS `animation-delay: calc(var(--i) * 80ms)` per item |

If the design team later produces Lottie files, drop the `.json` here
and use `lottie-react` to render.
