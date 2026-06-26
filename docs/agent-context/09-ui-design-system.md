# UI & Design System

**Confidence / Verification Status**: `VERIFIED`

## Theme
- The app uses `AppTheme.darkTheme` exclusively. Dark mode is default.
- Colors are defined in `lib/core/constants/app_color.dart`.

## Localization (l10n)
- **Tooling**: `flutter_localizations` with `.arb` files.
- **Location**: `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`.
- **Default Language**: Vietnamese (`vi_VN`).
- **Usage**: Hardcoding strings in UI is strictly prohibited. You must use `context.l10n.<key>`.

## Common Widgets
| Widget | Path | Purpose | Usage notes |
|---|---|---|---|
| `BrandMark` | `lib/shared/widgets/brand_mark.dart` | Logo/branding | Use on Splash/Login |
| `AuroraBackground` | `lib/shared/widgets/aurora_background.dart` | Background style | Used on Auth screens |
| `BottomNavBar` | `lib/shared/widgets/bottom_nav_bar.dart` | Shell navigation | Shell shell route |
| `PlaceholderCard` | `lib/shared/widgets/placeholder_card.dart` | Empty/Loading state | Use when no data |
| `SupabaseImage` | `lib/shared/widgets/supabase_image.dart` | Network image | Resolves signed URLs |

## Animations & Micro-interactions
- **Package**: `flutter_animate`
- **Lists and Grids**: Use staggered entrance animations for list items and grids (e.g., `.animate(delay: (30 * index).ms).fade().slideY(...)`) to create a fluid, cascading effect when data loads.
- **Hero Transitions**: Used primarily for images flying from a list/grid into a detail view. To create a clean "zoom out" popup effect, pair the destination `Hero` screen with `buildFadeTransitionPage` (avoid sliding page transitions). Ensure `fit` attributes match between source and destination (e.g., `BoxFit.cover`) to prevent glitchy image resizing. Place the `Hero` wrapper directly around the `SupabaseImage` unless the entire container is meant to cross-fade.

## Design Rules
- Follow Material 3 guidelines but lean heavily into custom dark-themed cards.
- Add graceful loading, empty, and error states for every screen.
- **Deep Aesthetic**: UI elements (like status pills, category/wallet icons) should avoid fully opaque, bright backgrounds. Instead, use a deep translucent effect. The standard pattern is a background of `color.withValues(alpha: 0.15)` paired with a foreground icon/text of `color`.
- **Polaroid-Style Image Overlay**: For image displays (like transaction previews or detail cards), use a 1:1 `AspectRatio` container with deeply rounded corners (`borderRadius: BorderRadius.circular(32)`). Overlays (Amount, Note, Date, Tags) should sit directly on the image, separated by dark-to-transparent `LinearGradient` wrappers (e.g., `Colors.black87` to `Colors.transparent`) to ensure text legibility while maintaining an immersive, focused aesthetic without disjointed frames.
- **Iconography**: Use `_outlined` icons globally. Avoid `_rounded`, `_filled`, or generic emojis.
- **Colors**: Do not use raw Material generic colors (`Colors.amber`, `#FF9800`, etc.) even in mock data. Always map to `AppTheme` colors (e.g., `AppTheme.amber`, `#F6B24D`) to maintain the deep consistency.
