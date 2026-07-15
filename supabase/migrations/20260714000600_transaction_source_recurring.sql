-- Recurring auto-post provenance.
-- Transactions materialized from a `recurring_transactions` rule are tagged
-- with source = 'recurring' so they can be told apart from manual/ocr/import
-- entries. Adding a value to an enum is safe and does not rewrite rows.
alter type public.transaction_source add value if not exists 'recurring';
