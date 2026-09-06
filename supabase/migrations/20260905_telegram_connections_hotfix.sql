-- ============================================================
-- EVRYLUX - TELEGRAM CONNECTIONS HOTFIX
-- Corrige instalações onde telegram_connections já existia
-- apenas com user_id/chat_id/enabled.
-- ============================================================

alter table if exists public.telegram_connections
  add column if not exists username text;

alter table if exists public.telegram_connections
  add column if not exists first_name text;

alter table if exists public.telegram_connections
  add column if not exists enabled boolean not null default true;

alter table if exists public.telegram_connections
  add column if not exists connected_at timestamptz not null default now();

alter table if exists public.telegram_connections
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists telegram_connections_chat_id_uidx
  on public.telegram_connections(chat_id);

alter table if exists public.telegram_connections enable row level security;

-- Recria as policies de forma idempotente.
drop policy if exists "telegram_connections_select_own"
  on public.telegram_connections;

create policy "telegram_connections_select_own"
  on public.telegram_connections
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "telegram_connections_update_own"
  on public.telegram_connections;

create policy "telegram_connections_update_own"
  on public.telegram_connections
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "telegram_connections_delete_own"
  on public.telegram_connections;

create policy "telegram_connections_delete_own"
  on public.telegram_connections
  for delete
  to authenticated
  using ((select auth.uid()) = user_id);

grant select, update, delete on table public.telegram_connections to authenticated;

notify pgrst, 'reload schema';
