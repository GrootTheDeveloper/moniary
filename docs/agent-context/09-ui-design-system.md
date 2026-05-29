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

## Design Rules
- Follow Material 3 guidelines but lean heavily into custom dark-themed cards.
- Add graceful loading, empty, and error states for every screen.
