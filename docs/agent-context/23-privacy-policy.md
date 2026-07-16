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
- **Assistant state and prompts**: assistant enablement/consent flags, user
  questions, limited chat history, profile name, and allowlisted financial
  summaries selected by those flags. When the assistant is enabled, this data
  is sent through a Supabase Edge Function to Google Gemini for a response.
- **Device files**: selected CSV imports, generated CSV/XLSX/PDF exports,
  journal recap PNGs, and local import/export history JSON. Privacy request
  history is stored in Supabase, not in a local JSON file.

## Purposes

Data is used to authenticate users, sync and display their finance records,
calculate calendar/statistics/budgets/recaps, provide verified assistant facts
and optional Gemini-generated explanations, manage friends/shared expenses, process user-requested OCR, send
configured reports, support exports/imports, and handle privacy/account actions.

## Service providers and disclosures

- **Supabase**: authentication, PostgreSQL data, private object Storage, RPCs,
  and Edge Functions.
- **Google Gemini**: receives the assistant question, limited history, profile
  context, and only the financial snapshot fields permitted by the user's
  server-side assistant settings when the AI assistant is enabled.
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
