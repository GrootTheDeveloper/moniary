# Index & Guide

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-10`

## Purpose

This directory is the agent-readable system context for Moniary. It describes
the current Flutter application, Supabase schema and Edge Functions, the local
OCR service, architecture boundaries, and engineering conventions.

When a document disagrees with executable code, use this source-of-truth order:

1. `lib/`, `supabase/`, `backend/ocr/`, and `pubspec.yaml`.
2. `AGENTS.md` and the strict architecture rules in `03-architecture.md`.
3. The current-state documents in this directory.
4. Historical plans under `docs/implementation/` and implementation specs such
   as `17-groups-community.md` and `18-ocr-pipeline.md`.

## Read by task

### New feature or behavior change

- `03-architecture.md`
- `04-features.md`
- `06-state-management.md`
- `07-routing-navigation.md`
- `16-directory-guide.md`
- `20-agent-task-playbook.md`

### Bug fix

- Trace `UI -> Controller/Provider -> Repository -> Data Source`.
- Read `14-error-handling-logging-observability.md`.
- Read the relevant entry in `04-features.md`.
- Check `21-known-risks-tech-debt.md` before widening scope.

### UI, design, or localization

- Read `09-ui-design-system.md`.
- Reuse `MoniaryColors`, `MoniaryTypography`, and shared design widgets.
- Add user-facing strings to both ARB files; never edit generated l10n files.

### Backend, data, or environment

- Read `05-data-models.md`, `08-api-and-integrations.md`, and
  `12-build-flavors-and-environments.md`.
- Preserve both authenticated Supabase mode and guest/mock data mode.
- Treat `supabase/migrations/` as the versioned schema and RLS definition.

### Specialized areas

- Groups and community: `17-groups-community.md` (detailed reference spec).
- Receipt OCR: `18-ocr-pipeline.md` and `19-ocr-backend.md`.
- Privacy/data handling: `23-privacy-policy.md` (engineering draft; legal review
  is still required before publication).

## Suggested first read

1. `01-system-overview.md`
2. `02-project-structure.md`
3. `03-architecture.md`
4. `04-features.md`
5. `20-agent-task-playbook.md`
