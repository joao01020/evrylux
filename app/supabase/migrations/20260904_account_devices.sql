-- ============================================================
-- EVRYLUX — ACCOUNT DEVICES / SESSIONS
-- ============================================================
--
-- Registra sessões reais do Supabase por instalação do EVRYLUX.
-- O session_id vem do JWT autenticado e é derivado no servidor.
--
-- Esta estrutura é separada dos dispositivos do Brain/E2EE.
-- ============================================================

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  session_id uuid not null,

  device_id text not null,

  device_name text not null,

  platform text not null,

  app_version text,

  created_at timestamptz not null default now(),

  last_seen_at timestamptz not null default now(),

  revoked_at timestamptz,

  ended_at timestamptz,

  constraint user_devices_device_id_not_blank
    check (length(trim(device_id)) > 0),

  constraint user_devices_device_name_not_blank
    check (length(trim(device_name)) > 0),

  constraint user_devices_platform_not_blank
    check (length(trim(platform)) > 0),

  constraint user_devices_user_session_unique
    unique (user_id, session_id)
);

create index if not exists user_devices_user_id_idx
  on public.user_devices (user_id);

create index if not exists user_devices_session_id_idx
  on public.user_devices (session_id);

create index if not exists user_devices_user_last_seen_idx
  on public.user_devices (user_id, last_seen_at desc);

create index if not exists user_devices_active_idx
  on public.user_devices (user_id, last_seen_at desc)
  where revoked_at is null
    and ended_at is null;

alter table public.user_devices
  enable row level security;

-- ============================================================
-- TABLE PRIVILEGES
-- ============================================================
--
-- O app pode somente ler as próprias linhas.
-- Toda escrita passa por RPC SECURITY DEFINER.
-- ============================================================

revoke all on table public.user_devices from anon;
revoke all on table public.user_devices from authenticated;

grant select on table public.user_devices to authenticated;

-- ============================================================
-- RLS — SELECT OWN
-- ============================================================

drop policy if exists user_devices_select_own
  on public.user_devices;

create policy user_devices_select_own
  on public.user_devices
  for select
  to authenticated
  using (
    user_id = auth.uid()
  );

-- ============================================================
-- REGISTER CURRENT SESSION / DEVICE
-- ============================================================
--
-- O session_id é lido do JWT do próprio usuário.
-- Um registro revogado/encerrado da MESMA sessão não é reativado.
-- Um novo login recebe outro session_id e pode registrar normalmente.
-- ============================================================

create or replace function public.register_user_device(
  p_device_id text,
  p_device_name text,
  p_platform text,
  p_app_version text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_session_id_text text := auth.jwt() ->> 'session_id';
  v_session_id uuid;
  v_active boolean := false;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if v_session_id_text is null or length(trim(v_session_id_text)) = 0 then
    raise exception 'Sessão sem session_id.';
  end if;

  v_session_id := v_session_id_text::uuid;

  if p_device_id is null or length(trim(p_device_id)) = 0 then
    raise exception 'device_id inválido.';
  end if;

  if p_device_name is null or length(trim(p_device_name)) = 0 then
    raise exception 'device_name inválido.';
  end if;

  if p_platform is null or length(trim(p_platform)) = 0 then
    raise exception 'platform inválido.';
  end if;

  insert into public.user_devices (
    user_id,
    session_id,
    device_id,
    device_name,
    platform,
    app_version,
    last_seen_at
  )
  values (
    v_user_id,
    v_session_id,
    trim(p_device_id),
    trim(p_device_name),
    trim(p_platform),
    nullif(trim(coalesce(p_app_version, '')), ''),
    now()
  )
  on conflict (user_id, session_id)
  do update
  set
    device_id = excluded.device_id,
    device_name = excluded.device_name,
    platform = excluded.platform,
    app_version = excluded.app_version,
    last_seen_at = now()
  where public.user_devices.revoked_at is null
    and public.user_devices.ended_at is null;

  select (
    d.revoked_at is null
    and d.ended_at is null
  )
    into v_active
  from public.user_devices as d
  where d.user_id = v_user_id
    and d.session_id = v_session_id
  limit 1;

  return coalesce(v_active, false);
end;
$$;

-- ============================================================
-- HEARTBEAT CURRENT SESSION
-- ============================================================

create or replace function public.touch_user_device(
  p_device_id text,
  p_device_name text,
  p_platform text,
  p_app_version text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_session_id_text text := auth.jwt() ->> 'session_id';
  v_session_id uuid;
  v_rows integer := 0;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if v_session_id_text is null or length(trim(v_session_id_text)) = 0 then
    raise exception 'Sessão sem session_id.';
  end if;

  v_session_id := v_session_id_text::uuid;

  update public.user_devices
  set
    device_id = trim(p_device_id),
    device_name = trim(p_device_name),
    platform = trim(p_platform),
    app_version = nullif(trim(coalesce(p_app_version, '')), ''),
    last_seen_at = now()
  where user_id = v_user_id
    and session_id = v_session_id
    and revoked_at is null
    and ended_at is null;

  get diagnostics v_rows = row_count;

  return v_rows = 1;
end;
$$;

-- ============================================================
-- REVOKE ANOTHER SESSION
-- ============================================================
--
-- Não permite revogar a sessão que está fazendo a chamada.
-- A sessão alvo será marcada como revogada; o cliente alvo faz
-- signOut(local) no próximo heartbeat.
-- ============================================================

create or replace function public.revoke_user_device(
  p_session_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_session_id_text text := auth.jwt() ->> 'session_id';
  v_current_session_id uuid;
  v_rows integer := 0;
begin
  if v_user_id is null then
    raise exception 'Usuário não autenticado.';
  end if;

  if v_current_session_id_text is null or length(trim(v_current_session_id_text)) = 0 then
    raise exception 'Sessão sem session_id.';
  end if;

  v_current_session_id := v_current_session_id_text::uuid;

  if p_session_id = v_current_session_id then
    raise exception 'Não é permitido revogar a sessão atual por esta função.';
  end if;

  update public.user_devices
  set revoked_at = coalesce(revoked_at, now())
  where user_id = v_user_id
    and session_id = p_session_id
    and revoked_at is null
    and ended_at is null;

  get diagnostics v_rows = row_count;

  return v_rows = 1;
end;
$$;

-- ============================================================
-- NORMAL LOGOUT / END CURRENT SESSION
-- ============================================================
--
-- Chamado imediatamente antes do signOut() normal do app.
-- ============================================================

create or replace function public.disconnect_current_user_device()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_session_id_text text := auth.jwt() ->> 'session_id';
  v_session_id uuid;
  v_rows integer := 0;
begin
  if v_user_id is null then
    return false;
  end if;

  if v_session_id_text is null or length(trim(v_session_id_text)) = 0 then
    return false;
  end if;

  v_session_id := v_session_id_text::uuid;

  update public.user_devices
  set ended_at = coalesce(ended_at, now())
  where user_id = v_user_id
    and session_id = v_session_id
    and ended_at is null;

  get diagnostics v_rows = row_count;

  return v_rows = 1;
end;
$$;

-- ============================================================
-- FUNCTION PRIVILEGES
-- ============================================================

revoke all on function public.register_user_device(text, text, text, text)
  from public;
revoke all on function public.touch_user_device(text, text, text, text)
  from public;
revoke all on function public.revoke_user_device(uuid)
  from public;
revoke all on function public.disconnect_current_user_device()
  from public;

grant execute on function public.register_user_device(text, text, text, text)
  to authenticated;
grant execute on function public.touch_user_device(text, text, text, text)
  to authenticated;
grant execute on function public.revoke_user_device(uuid)
  to authenticated;
grant execute on function public.disconnect_current_user_device()
  to authenticated;

notify pgrst, 'reload schema';
