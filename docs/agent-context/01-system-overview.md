# System Overview

**Confidence / Verification Status**: `VERIFIED`

## What this app does
Moniary is a personal finance management mobile application built with Flutter. It allows users to track their expenses, manage wallets, categorize transactions, scan receipts (OCR), and manage group expenses/debts.

## Main user journeys
1. **Onboarding & Auth**: First-time users see an onboarding flow. Users can setup their profile and log in.
2. **Transaction Management**: Users view a calendar or list of transactions, add new transactions manually, or use the camera to scan receipts.
3. **Wallet & Category Management**: Managing different sources of funds and types of expenses.
4. **Group Expenses & Debts**: Splitting bills with friends and calculating who owes whom.
5. **Statistics**: Viewing spending trends and charts.
6. **Data Export & Privacy**: Exporting data to CSV/PDF and requesting data deletion.

## Main modules
- **Transactions**: Core expense tracking.
- **Calendar**: Month/day view of finances.
- **Wallets & Categories**: Core entities for classifying transactions.
- **Scanning (OCR)**: Receipt parsing.
- **Groups**: Bill splitting and debt tracking.
- **Settings/Profile**: User preferences, legal, privacy, data export.
- **Auth**: Supabase authentication.

## External systems
- **Supabase**: Used for PostgreSQL Database, Authentication, and Storage (for receipt images).
- **Mock Mode**: The app can run entirely offline with mock data if Supabase credentials (`SUPABASE_URL` and `SUPABASE_ANON_KEY`) are not provided in the environment.

## Important assumptions
- The app defaults to Vietnamese.
- The UI is designed for a dark theme (`AppTheme.darkTheme`).
