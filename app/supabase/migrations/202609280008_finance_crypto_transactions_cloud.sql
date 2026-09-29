-- EVRYLUX
create table if not exists public.finance_crypto_transactions (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  symbol text not null,
  date timestamptz not null,
  quantity double precision not null default 0,
  invested double precision not null default 0,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.finance_crypto_transactions enable row level security;

drop policy if exists finance_crypto_transactions_select_own on public.finance_crypto_transactions;
create policy finance_crypto_transactions_select_own
  on public.finance_crypto_transactions for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists finance_crypto_transactions_insert_own on public.finance_crypto_transactions;
create policy finance_crypto_transactions_insert_own
  on public.finance_crypto_transactions for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists finance_crypto_transactions_update_own on public.finance_crypto_transactions;
create policy finance_crypto_transactions_update_own
  on public.finance_crypto_transactions for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists finance_crypto_transactions_delete_own on public.finance_crypto_transactions;
create policy finance_crypto_transactions_delete_own
  on public.finance_crypto_transactions for delete to authenticated
  using (auth.uid() = user_id);

create index if not exists finance_crypto_transactions_user_symbol_date_idx
  on public.finance_crypto_transactions (user_id, symbol, date desc);
