# Storage, Cache & Offline

**Confidence / Verification Status**: `VERIFIED`

## Local Preferences
- **Package**: `shared_preferences`
- **Location**: `lib/core/preferences/`
- **Purpose**: Store simple keys like `onboarding_seen`.

## Mock Data Mode
- **Switch**: `AppConstants.hasSupabaseConfig`
- **Behavior**: If `false`, repositories (e.g., `TransactionRepository`) use in-memory static lists (`_mockTransactions`) instead of hitting Supabase. 
- **Offline Implication**: This mock mode allows the app to function without internet, but data is lost on app restart if not persisted. Currently, mock lists are in-memory.

## Image Caching & Storage
- Supabase Storage is used for uploading receipt images.
- Images are retrieved via Signed URLs which are cached/managed by `SignedUrlProvider`.
- Temporary directory is used via `path_provider` during mock mode image selection.
