# Moniary Privacy & Data-Handling Draft

**Document status**: `ENGINEERING DRAFT — LEGAL REVIEW REQUIRED`
**Source audit date**: `2026-07-10`

This document records data handling visible in the current repository. It is not
a substitute for counsel-approved privacy policy, store disclosure, retention
schedule, or the public policy URL required for production.

## Data processed by current features

- **Account/profile**: user ID, authentication provider/identities, email,
  display name, username, avatar path, timezone, occupation, preferred currency,
  and profile-survey completion.
- **Personal finance**: wallets, categories, transactions, dates, amounts,
  notes, importance state, category budget limits/warning ratios, and optional
  receipt images.
- **Friends/groups**: searches and requests, friendships/invite links, group
  membership/roles, shared transactions, payers, shares, balances, settlements,
  comments, invitations, activities/notifications, and group images.
- **Settings/account operations**: notification/report preferences, active
  sessions, deletion status/feedback, privacy-request history, app lock and
  hidden-balance preferences.
- **Local assistant state**: assistant enablement/consent flags and deterministic
  summaries calculated from repository transactions. The current assistant does
  not send prompts or finance data to an AI model.
- **Device files**: selected CSV imports, generated CSV/XLSX/PDF exports, journal
  recap PNGs, and local import/export/privacy-request history JSON.

## Purposes

Data is used to authenticate users, sync and display their finance records,
calculate calendar/statistics/budgets/recaps, provide deterministic assistant
insights, manage friends/shared expenses, process user-requested OCR, send
configured reports, support exports/imports, and handle privacy/account actions.

## Service providers and disclosures

- **Supabase**: authentication, PostgreSQL data, private object Storage, RPCs,
  and Edge Functions.
- **Configured OCR host**: receives a receipt image when the user starts OCR.
  The repository implementation is FastAPI/Tesseract; the production host and
  its operational retention policy must be disclosed.
- **Resend**: receives report email content/recipient data when scheduled email
  reports are enabled and the Edge Function is configured.
- **Operating-system share/open targets**: receive files only when the user
  explicitly shares or opens an export/recap through another app.

Moniary source does not implement sale of personal/financial data, contact-book
access, SMS reading, email-inbox reading, location collection, or automatic bank
transaction import.

## Images, permissions, and sensitive financial data

Camera/photo access is user initiated for receipts, transaction/group images, and
avatars. Biometric APIs can gate local app access. Financial amounts can be
hidden in UI, but this display preference does not encrypt backend/local data.

Supabase Storage paths are private and displayed through signed URLs according
to repository policies. Production must verify the deployed Storage/RLS policy
set with multiple accounts.

## Retention, export, and deletion

The app provides transaction deletion, data export, privacy requests, soft
account deletion, final deletion, and garbage-collection backend components.
Exact production retention/grace periods must match the deployed functions and
published policy.

Account deletion does not necessarily remove files the user already exported,
shared to other apps, or saved locally, nor device preferences/history outside
the remote account. The final product must explain how users can remove those
local/external copies.

## Anonymous accounts

The no-credentials entry point creates a real Supabase anonymous account.
Anonymous data is stored in the cloud, is subject to the documented inactivity
cleanup period, and can be upgraded in place to email, Google, or Facebook.

## Before production publication

Legal/Product must verify actual deployed hosts, subprocessors, OAuth providers,
report delivery, retention periods, deletion behavior, contact addresses, user
rights, age/region requirements, and Google Play/App Store disclosures. Publish
the approved policy at a stable public URL and keep the in-app text synchronized.
