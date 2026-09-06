-- ============================================================
-- EVRYLUX - TELEGRAM CONNECTIONS
-- ============================================================

create table if not exists public.telegram_connections (
  user_id uuid primary key references auth.users(id) on delete cascade,
  chat_id text not null unique,
  username text,
  first_name text,
  enabled boolean not null default true,
  connected_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);


-- Compatibilidade com uma tabela telegram_connections que já exista
-- com apenas user_id/chat_id/enabled (a send-reminders atual já prevê isso).
alter table public.telegram_connections
  add column if not exists username text;

alter table public.telegram_connections
  add column if not exists first_name text;

alter table public.telegram_connections
  add column if not exists enabled boolean not null default true;

alter table public.telegram_connections
  add column if not exists connected_at timestamptz not null default now();

alter table public.telegram_connections
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists telegram_connections_chat_id_uidx
  on public.telegram_connections(chat_id);

create table if not exists public.telegram_link_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists telegram_link_requests_user_id_idx
  on public.telegram_link_requests(user_id);

create index if not exists telegram_link_requests_expires_at_idx
  on public.telegram_link_requests(expires_at);

alter table public.telegram_connections enable row level security;
alter table public.telegram_link_requests enable row level security;

-- O usuário pode somente ler/alterar/remover a própria conexão.
-- A criação da conexão é feita pelo webhook com service role.

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

-- Não há policies para telegram_link_requests.
-- Apenas Edge Functions com service role acessam essa tabela.

revoke all on table public.telegram_link_requests from anon, authenticated;
grant select, update, delete on table public.telegram_connections to authenticated;

comment on table public.telegram_connections is
  'Vínculo entre usuário EVRYLUX e chat privado do Telegram.';

comment on table public.telegram_link_requests is
  'Tokens temporários e de uso único para vincular Telegram ao usuário EVRYLUX.';
