# UI & Design System

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## Current visual foundation

Moniary currently uses a warm light editorial theme from
`lib/app/app_theme.dart`:

- Background/surfaces: parchment and warm white.
- Primary accent: terracotta, with sage/forest/sand/dusty-rose support colors.
- Body/UI font: Manrope.
- Editorial display font: Instrument Serif.
- Metadata/eyebrow font: JetBrains Mono.

`AppTheme.lightTheme` is passed to `MaterialApp`.
`AppTheme.darkTheme` currently returns the light theme for compatibility; do
not describe the product as dark-mode-only.

## Theme access

- Use `context.moniaryColors` for semantic colors.
- Use `context.moniaryTypography` for editorial display and metadata styles.
- Compatibility constants remain on `AppTheme`, but new UI should prefer the
  theme extensions where a `BuildContext` exists.
- Do not introduce raw generic Material colors or ad-hoc hex colors when an
  existing semantic token fits.

The frozen foundation was derived from
`docs/design/moniary-screen-showcase.html`. Shared primitives are in
`lib/shared/widgets/moniary_design.dart`.

## Localization

- Source ARB files: `lib/l10n/app_vi.arb` and `app_en.arb`.
- Primary/default product locale: Vietnamese.
- Use `context.l10n.<key>` in presentation.
- Add/update both ARB files together.
- Never edit `lib/l10n/gen_l10n/` manually; run `flutter gen-l10n` or a
  Flutter build.

## Shared widgets

| Widget/file | Purpose |
|---|---|
| `BrandMark` | Product mark for onboarding/auth |
| `AuroraBackground` | Legacy/shared decorative background |
| `MoniaryBottomNavBar` | Four-tab shell plus centered camera action |
| `SupabaseImage` | Local/private Supabase image display through signed URLs |
| `ObscurableAmountText` | Honors hidden-balance privacy state |
| `PlaceholderCard` | Empty/loading/error content |
| `moniary_design.dart` | Editorial page headers, cards, labels, and layout primitives |

## Interaction rules

- Provide explicit loading, empty, error, and retry states for async screens.
- Use fade transitions for image Hero destinations and keep source/destination
  image fit consistent.
- Use `flutter_animate` sparingly for meaningful staged entrances.
- Prefer outlined Material icons as established by the app.
- Preserve accessibility semantics for custom icon buttons, navigation, camera,
  assistant, and privacy-sensitive controls.
- Keep amount display routed through privacy-aware widgets when balances may be
  hidden.
