# Supabase migration history

Migration filenames are part of the production contract. Every file must have
one globally unique 14-digit version; never resolve a branch conflict by
keeping two files with the same numeric prefix.

## 2026-07-15 branch reconciliation

Three versions collided while the group and recurring branches were developed
in parallel. The canonical sequence is now:

- `20260714000300`: exact-split enum;
- `20260714000500`: social financial guards;
- `20260714000600`: compatibility marker for the historical collision;
- `20260715000100`: group leave guards and notification channels;
- `20260715000200`: notification inbox and device registration;
- `20260715000300`: idempotent reconciliation of group lifecycle notifications
  and the recurring transaction source enum.

The final reconciliation intentionally recreates functions/triggers and uses
`add value if not exists`. It therefore repairs a database that previously ran
either meaning of `20260714000600`, while a fresh database receives both.

`test/supabase/migration_history_test.dart` rejects duplicate or malformed
versions in CI. Run it before every schema deployment:

```bash
flutter test test/supabase/migration_history_test.dart
```

## Production preflight

Use the database connection string from the same project as `SUPABASE_URL`.
Do not reuse an `.env` copied from another Supabase project. Prefer the session
pooler URL on port 5432 for migration commands.

First compare local and remote history without changing the database:

```bash
supabase migration list --db-url "$DATABASE_URL"
```

The same history can be inspected in the project SQL Editor:

```sql
select *
from supabase_migrations.schema_migrations
order by version;
```

Do not run `migration repair` just to silence a mismatch. Repair only a version
whose SQL effects have been independently verified in that exact project. Once
the list is consistent, apply pending migrations through the normal deployment
workflow and keep the command output with the release record.
