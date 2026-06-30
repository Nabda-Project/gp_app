# /assets/images — intentionally empty

There are **no raster illustrations** to copy from the Flutter app.

`lib/utils/constants.dart:47-53` declares placeholder paths
(`assets/images/logo.png`, `assets/icons/doctor.png`,
`assets/icons/patient.png`, `assets/images/onboarding.png`), but those
files do NOT exist in the repo and `pubspec.yaml` does not register an
`assets:` block.

The visual identity is delivered via:

- The NABDA ECG logo → `/assets/logos/nabda-logo.svg` (re-authored from
  the Flutter `CustomPaint`).
- Decorative circles → CSS positioned `<div>`s (see DESIGN_SYSTEM.md
  §3.7).
- Material icons → see `/assets/icons/README.md`.

If at any point the design team produces real illustrations (e.g.
hero images, empty-state artwork), drop them in this folder as SVGs.
