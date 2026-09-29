-- EVRYLUX
-- Two-way crypto synchronization Web <-> Desktop.

alter table public.finance_crypto_transactions
  add column if not exists deleted_at timestamptz;

alter table public.finance_crypto_transactions
  add column if not exists updated_at timestamptz not null default now();

create index if not exists finance_crypto_transactions_user_updated_idx
on public.finance_crypto_transactions (user_id, updated_at desc);

create index if not exists finance_crypto_transactions_user_deleted_idx
on public.finance_crypto_transactions (user_id, deleted_at);

comment on column public.finance_crypto_transactions.deleted_at is
  'Soft-delete timestamp used to synchronize deletions across devices.';
