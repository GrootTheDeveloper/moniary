# Privacy request operations

The mobile app submits privacy requests to `public.privacy_requests`. Users can
insert and read only their own requests. They cannot edit a status or erase the
audit trail; processing must run from the Supabase SQL Editor or a trusted
service-role worker.

## Review the queue

Run with an administrator connection:

```sql
select id, user_id, request_type, message, status, submitted_at
from public.privacy_requests
where status in ('submitted', 'in_review')
order by submitted_at asc;
```

Claim a request before beginning work:

```sql
update public.privacy_requests
set status = 'in_review',
    admin_note = 'Request is being reviewed.'
where id = '<REQUEST_UUID>'
  and status = 'submitted';
```

Complete it with a user-safe response. `admin_note` is visible to the submitting
user, so never put internal credentials, private staff notes, or third-party
personal data there.

```sql
update public.privacy_requests
set status = 'resolved',
    admin_note = '<USER_SAFE_RESPONSE>',
    resolved_at = timezone('utc', now())
where id = '<REQUEST_UUID>'
  and status = 'in_review';
```

Use `rejected` only with a clear user-safe reason and set `resolved_at` in the
same statement. Never update `user_id`, `request_type`, `message`, or
`submitted_at`. Retention/deletion of this audit table must be handled by a
separate approved privacy policy; the app intentionally exposes no delete RPC.
