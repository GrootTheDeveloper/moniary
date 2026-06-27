# Index & Guide

**Confidence / Verification Status**: `VERIFIED`

## Purpose of this Documentation
This directory contains the system context for the Moniary Flutter application. It is designed to allow AI coding agents and human developers to understand the architecture, conventions, and state of the codebase quickly without needing to index the entire project manually.

## How to use this guide

### 1. New Feature Development
Read these files first:
- `03-architecture.md` (To understand boundaries)
- `04-features.md` (To check if a similar feature exists)
- `06-state-management.md` (To understand Riverpod usage)
- `07-routing-navigation.md` (To learn how to add routes)
- `16-directory-guide.md` (To place files correctly)
- `20-agent-task-playbook.md` (Follow the New Feature checklist)

### 2. Bug Fixing
- Trace from UI -> Controller -> Repository.
- Read `14-error-handling-logging-observability.md`.
- Read the relevant feature in `04-features.md`.
- Consult `21-known-risks-tech-debt.md` in case it is a known issue.

### 3. Refactoring
- Review `15-coding-conventions.md`, `16-directory-guide.md`, and `03-architecture.md`.
- Ensure you do not break the "Mock Mode" (see `10-storage-cache-and-offline.md`).

### 4. UI or Localization Changes
- Review `09-ui-design-system.md`.
- Do not hardcode strings. Always use `lib/l10n/` ARB files.

### 5. Backend / API / Supabase Changes
- Review `08-api-and-integrations.md` and `05-data-models.md`.
- Be mindful of the toggle `AppConstants.hasSupabaseConfig`.

### 6. Groups & Community Feature
- Read `17-groups-community.md` for feature context and agent instructions.

### 7. OCR Pipeline
- Read `18-ocr-pipeline.md` for the receipt OCR pipeline architecture and rules.
- Read `19-ocr-backend.md` for backend integration details.

## Suggested Reading Order
1. `01-system-overview.md`
2. `02-project-structure.md`
3. `03-architecture.md`
4. `20-agent-task-playbook.md`
