-- Distinguish records that intentionally have no attachment from uploads that
-- are still pending. PostgreSQL enum values must be committed before a later
-- migration can use them in defaults or constraints.
alter type public.image_upload_status add value if not exists 'none';
