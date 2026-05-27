# Moniary Privacy Policy

Last updated: 2026-05-25

Moniary is a personal expense diary app that helps users record income and expenses with optional transaction photos. This policy describes the data handled by the MVP version of the app.

## Data We Process

- Account data: display name, email, avatar, provider and user ID when a user signs in.
- Financial data: wallets, categories, transactions, amounts, notes and transaction dates entered by the user.
- Photos: transaction photos that the user chooses or captures in the app.
- App settings: profile, timezone and notification preferences.

## How We Use Data

- To authenticate users and sync their data across devices.
- To show calendar, transaction detail, filters and monthly summaries.
- To store transaction photos in private Supabase Storage and show them through signed URLs.
- To protect user data with row-level security and account-based access control.

## Sharing

Moniary does not sell personal or financial data. MVP data is stored with Supabase services for authentication, database and storage. The MVP does not collect location, contacts, SMS, email inbox data or automatic bank transaction imports.

## Retention And Deletion

Users can delete transactions in the app. Users can export their transaction data as CSV before deleting the account. Account deletion requests remove the user's app data and transaction photos associated with the current user ID.

## Google Play Data Safety Notes

- Personal info is collected only when users sign in with email or Google.
- Financial info is collected to provide expense tracking features.
- Photos are collected only when users actively choose or capture transaction photos.
- Location, Contacts and SMS are not collected in the MVP.

Before production release, publish this policy at a public URL and replace this note with the team's official contact email.
