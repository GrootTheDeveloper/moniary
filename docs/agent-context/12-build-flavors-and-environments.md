# Build Flavors & Environments

**Confidence / Verification Status**: `VERIFIED`

## Environments
- **Variables**: `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
- **Injection**: Handled via `String.fromEnvironment()` in `lib/core/constants/app_constants.dart`.
- **Release Mode**: If the app is compiled in release mode (`kReleaseMode`), the app will throw a fatal error if Supabase credentials are missing. In debug mode, it gracefully falls back to Mock Mode.

## Build Commands
```bash
# Debug Mode (Mock Mode if without args)
flutter run

# Debug Mode (with Supabase)
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Release Build
flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

There are no explicit flavor setups (like `dev`/`staging`/`prod` flavors configured natively in gradle or Xcode) seen in the current directory structure, so everything relies on `--dart-define`.
