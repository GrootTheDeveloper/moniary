# Open Questions

**Confidence / Verification Status**: `VERIFIED AGAINST SOURCE`
**Last source audit**: `2026-07-12`

| Question | Why it matters | Evidence/owner |
|---|---|---|
| Have all 15 Supabase migrations been applied to each active environment? | Code now depends on budget, journal, profile-survey, friend, group-invite, account, RLS, and RPC objects. | Compare remote migration status with `supabase/migrations/`; Backend/DevOps. |
| Are Google/Facebook/Apple providers and all mobile callback URLs configured and tested? | Repository code exists, but provider dashboards and redirect allowlists are external state. | `auth_repository.dart`, Android/iOS URL config; Mobile/Backend. |
| Where will production OCR be hosted and monitored? | Release devices need a reachable HTTPS service with Tesseract languages installed. | `backend/ocr/`, `OCR_API_URL`; Backend/DevOps. |
| Are scheduled reports deployed with a verified Resend sender, secrets, cron, and deletion-safe behavior? | Source implementation alone does not guarantee delivery or privacy operations. | `supabase/functions/scheduled-reports/`, scheduling migration; Backend/Legal. |
| What is the supported persistence promise for guest users? | Current mock data is largely in memory and can disappear on restart. | Mock repositories/data sources; Product. |
| Has the privacy/data-safety text been legally reviewed and published at a stable public URL? | Store submission and real processing disclosures must match deployed providers/features. | `23-privacy-policy.md`, in-app legal screens; Legal/Product. |
