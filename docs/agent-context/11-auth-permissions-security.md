# Auth, Permissions & Security

**Confidence / Verification Status**: `VERIFIED`

## Authentication
- **Provider**: Supabase Auth.
- **Initialization**: `supabase_bootstrap.dart`
- **Flow**: Anonymous login is standard for first-time use. Users can link credentials later if needed. The `auth_controller.dart` handles the login process.
- **Session State**: Riverpod listens to `onAuthStateChange` to trigger `go_router` redirects automatically.

## Permissions
- **Camera/Photos**: Handled via `image_picker` and `camera` plugins for receipt scanning and profile pictures.
- **Rationale**: Before asking for permissions, the app explains why it needs them (e.g., `PermissionRationaleScreen`).

## Data Security & RLS
- **Verification Status**: `NEEDS_VERIFICATION`. Row Level Security (RLS) is expected on Supabase but SQL schemas and policies are not present in the repository itself. We assume `user_id` filtering in Repositories maps securely to backend RLS policies.

## Secrets
- API keys (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) are passed via `--dart-define` at compile time and never hardcoded in Dart source.
