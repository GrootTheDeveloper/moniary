# Agent Task Playbook

**Confidence / Verification Status**: `VERIFIED`

This is the standard operating procedure for AI agents modifying this codebase.

## When Adding a New Feature
1. Read `AGENTS.md` and `00-index.md`.
2. Check `04-features.md` to ensure it doesn't already exist.
3. Understand the architecture in `03-architecture.md`.
4. Create the required feature structure (`presentation`, `application`, `domain`, `data`).
5. Build the UI adhering to `09-ui-design-system.md` and using `l10n` for text.
6. Connect UI to logic via Riverpod Controllers (`06-state-management.md`).
7. Create Repositories that support BOTH Supabase Mode and Mock Mode.
8. Add routes to `app_router.dart` (`07-routing-navigation.md`).
9. Update `04-features.md` documentation to include the new feature.
10. Run `flutter analyze` and `flutter test`.

## When Fixing a Bug
1. Identify the feature module.
2. Read related docs.
3. Reproduce the issue conceptually or via tests.
4. Fix the root cause, respecting Clean Architecture boundaries.
5. Check if the fix breaks Mock Mode or Supabase Mode.
6. Verify l10n is still correct if it's a UI issue.
7. Run `flutter analyze` and `flutter test`.

## When Refactoring
1. **DO NOT** change behavior unless requested.
2. **DO NOT** rewrite the architecture or state management framework.
3. Keep changes small.
4. Check `flutter analyze`.
5. Update docs if folder structure or conventions change.

## When Adding a Screen
1. Place it in `lib/features/<feature_name>/presentation/`.
2. Add route definition in `app_router.dart`.
3. Do not fetch data directly; use a Riverpod Controller/Provider.
4. Handle loading/empty/error states gracefully.

## When Modifying Localization
1. Edit `lib/l10n/app_vi.arb` (and English if available).
2. Do not put display text in the Repository.
3. Keep Vietnamese as the primary focus.
