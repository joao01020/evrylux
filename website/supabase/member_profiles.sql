-- EVRYLUX Members
-- Execute este SQL no SQL Editor do seu projeto Supabase.

create table if not exists public.member_profiles (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null unique
    references auth.users(id)
    on delete cascade,

  display_name text,
  github_login text,
  bio text,
  avatar_url text,
  area text,
  skills text,
  availability text,

  created_at timestamptz
    not null
    default now(),

  updated_at timestamptz
    not null
    default now()
);

alter table public.member_profiles
  enable row level security;

drop policy if exists
  "member_profiles_select_own"
  on public.member_profiles;

create policy
  "member_profiles_select_own"
on public.member_profiles
for select
to authenticated
using (
  auth.uid() = user_id
);

drop policy if exists
  "member_profiles_insert_own"
  on public.member_profiles;

create policy
  "member_profiles_insert_own"
on public.member_profiles
for insert
to authenticated
with check (
  auth.uid() = user_id
);

drop policy if exists
  "member_profiles_update_own"
  on public.member_profiles;

create policy
  "member_profiles_update_own"
on public.member_profiles
for update
to authenticated
using (
  auth.uid() = user_id
)
with check (
  auth.uid() = user_id
);

-- Nesta primeira versão não existe delete pelo site.
-- Cada usuário autenticado só lê/cria/edita o próprio perfil.
