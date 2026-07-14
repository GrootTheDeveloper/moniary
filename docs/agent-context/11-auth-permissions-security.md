# Auth, Permissions & Security

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## Authentication

Supabase Auth is initialized with PKCE when real configuration is present.
`AuthRepository` supports:

- email/password sign-in and sign-up;
- password-reset request and recovery completion with a new password;
- Google and Facebook OAuth;
- anonymous Supabase sign-in;
- explicit guest/mock session;
- linking email or Google identity to an existing account;
- sign-out and user initialization.

In mock/guest mode these flows return or maintain a synthetic
`mock-user-id` session and must not access configured user data.

Anonymous-to-email upgrades are two-phase. The app first updates only the
email and stores the originating user ID plus normalized email locally. After
Supabase confirms the email and returns the same user, the app opens a separate
password step, then updates the profile provider. It never reports a completed
email link before both phases succeed.

Google identity linking is also callback-driven. The repository supplies the
mobile redirect and checks that the external browser launched. A persisted
pending record is bound to the originating user ID; after callback, the app
verifies that the same user now has a Google identity before updating the
profile and showing success. No fixed delay is used as a completion signal.

## Session and route security

- Supabase auth changes are exposed as a `StreamProvider`.
- `currentSessionProvider` prefers the mock session, then the Supabase session.
- Account soft-deletion state and app-lock state refresh global redirects.
- Pending friend deep links are held in a Riverpod notifier until login/profile
  setup is complete.
- The app locks on paused/hidden lifecycle states when app lock is enabled.

## Deep links

- Friend invites: `https://go.vuivethoima.id.vn/friends/invite/<token>`;
  legacy `moniary://friends/invite/<token>` is still parsed.
- Group invites: `https://go.vuivethoima.id.vn/groups/invite/<token>`;
  legacy `moniary://groups/invite/<token>` is still parsed.
- Supabase OAuth callback: `io.supabase.moniary://login-callback`.
- Password reset callback: `io.supabase.moniary://reset-password`.

Supabase Flutter consumes the PKCE recovery callback and emits
`AuthChangeEvent.passwordRecovery`. The app routes that event to the public
`/reset-password` form, updates the password, and clears the temporary recovery
session before returning to login. Mock mode opens the same form directly.

Platform intent/URL registration and provider dashboard redirect allowlists must
remain aligned with these values.

## Permissions

The project declares/configures camera, photo/media access, networking, and
biometric permissions in the platform projects. Camera/photo access is used only
for user-initiated receipt/avatar flows. `PermissionRationaleScreen` contains
the in-app rationale content.

Any new permission requires platform manifest/plist updates, a localized
rationale, and privacy/data-safety review.

## Database and Storage security

The repository now includes RLS and Storage policies in
`supabase/migrations/` for core finance, groups, friends, budgets, journal, and
related account data. RPCs enforce multi-row group/friend operations where
appropriate.

This is source-level verification only. Before production release, verify the
remote project has applied all migrations and test RLS with multiple real users;
client-side `user_id` filters are not a security boundary.

## Secrets

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `OCR_API_URL` are compile-time
Dart defines. Edge Function secrets such as `RESEND_API_KEY` belong in the
Supabase environment. Never commit access tokens, service-role keys, signing
secrets, or production credentials.
