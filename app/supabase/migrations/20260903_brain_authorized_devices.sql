begin;
create extension if not exists pgcrypto;

create table if not exists public.brain_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vault_id text not null,
  device_id text not null,
  device_name text not null,
  public_key_b64 text not null,
  key_fingerprint text not null,
  auth_secret_hash bytea not null,
  status text not null default 'pending'
    check (status in ('pending','authorized','revoked')),
  created_at timestamptz not null default now(),
  authorized_at timestamptz,
  revoked_at timestamptz,
  last_seen_at timestamptz,
  unique(user_id,vault_id,device_id)
);

create index if not exists brain_devices_user_vault_idx
  on public.brain_devices(user_id,vault_id);

alter table public.brain_devices enable row level security;
drop policy if exists brain_devices_select_own on public.brain_devices;
create policy brain_devices_select_own
  on public.brain_devices for select to authenticated
  using (user_id = auth.uid());
revoke insert,update,delete on public.brain_devices from authenticated;
grant select on public.brain_devices to authenticated;

create table if not exists public.brain_device_key_envelopes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vault_id text not null,
  envelope_id text not null,
  sender_device_id text not null,
  target_device_id text not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  consumed_at timestamptz,
  unique(user_id,vault_id,envelope_id)
);

alter table public.brain_device_key_envelopes enable row level security;
drop policy if exists brain_device_key_envelopes_select_own on public.brain_device_key_envelopes;
create policy brain_device_key_envelopes_select_own
  on public.brain_device_key_envelopes for select to authenticated
  using (user_id = auth.uid());
revoke insert,update,delete on public.brain_device_key_envelopes from authenticated;
grant select on public.brain_device_key_envelopes to authenticated;

create or replace function public._brain_device_authorized_internal(
  p_user_id uuid,
  p_vault_id text,
  p_device_id text,
  p_auth_secret text
) returns boolean
language sql stable security definer set search_path=public
as $$
  select exists(
    select 1 from public.brain_devices d
    where d.user_id=p_user_id
      and d.vault_id=p_vault_id
      and d.device_id=p_device_id
      and d.status='authorized'
      and d.auth_secret_hash=extensions.digest(convert_to(p_auth_secret, 'UTF8'), 'sha256')
  );
$$;
revoke all on function public._brain_device_authorized_internal(uuid,text,text,text) from public,authenticated;

create or replace function public.register_brain_device(
  p_device_id text,
  p_vault_id text,
  p_device_name text,
  p_public_key_b64 text,
  p_key_fingerprint text,
  p_auth_secret text
) returns jsonb
language plpgsql security definer set search_path=public
as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
  v_row public.brain_devices;
begin
  if v_user_id is null then raise exception 'unauthenticated'; end if;
  if nullif(trim(p_device_id),'') is null
     or nullif(trim(p_vault_id),'') is null
     or nullif(trim(p_device_name),'') is null
     or nullif(trim(p_public_key_b64),'') is null
     or nullif(trim(p_key_fingerprint),'') is null
     or nullif(trim(p_auth_secret),'') is null then
    raise exception 'invalid_device_registration';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_user_id::text || ':' || p_vault_id));

  if exists(
    select 1 from public.brain_devices d
    where d.user_id=v_user_id and d.vault_id=p_vault_id and d.status='authorized'
  ) then v_status:='pending'; else v_status:='authorized'; end if;

  insert into public.brain_devices(
    user_id,vault_id,device_id,device_name,public_key_b64,key_fingerprint,
    auth_secret_hash,status,authorized_at,last_seen_at
  ) values(
    v_user_id,trim(p_vault_id),trim(p_device_id),trim(p_device_name),
    trim(p_public_key_b64),trim(p_key_fingerprint),extensions.digest(convert_to(p_auth_secret, 'UTF8'), 'sha256'),
    v_status,case when v_status='authorized' then now() else null end,now()
  )
  on conflict(user_id,vault_id,device_id) do update set
    device_name=excluded.device_name,
    last_seen_at=now()
  returning * into v_row;

  return jsonb_build_object(
    'device_id',v_row.device_id,'vault_id',v_row.vault_id,'device_name',v_row.device_name,
    'public_key_b64',v_row.public_key_b64,'key_fingerprint',v_row.key_fingerprint,
    'status',v_row.status,'created_at',v_row.created_at,'authorized_at',v_row.authorized_at,
    'revoked_at',v_row.revoked_at,'last_seen_at',v_row.last_seen_at
  );
end;
$$;
grant execute on function public.register_brain_device(text,text,text,text,text,text) to authenticated;

create or replace function public.brain_device_is_authorized(
  p_vault_id text,p_device_id text,p_auth_secret text
) returns boolean
language plpgsql security definer set search_path=public
as $$
declare v_user_id uuid:=auth.uid(); v_ok boolean;
begin
  if v_user_id is null then return false; end if;
  v_ok:=public._brain_device_authorized_internal(v_user_id,p_vault_id,p_device_id,p_auth_secret);
  if v_ok then
    update public.brain_devices set last_seen_at=now()
    where user_id=v_user_id and vault_id=p_vault_id and device_id=p_device_id;
  end if;
  return v_ok;
end;
$$;
grant execute on function public.brain_device_is_authorized(text,text,text) to authenticated;

create or replace function public.approve_brain_device(
  p_vault_id text,
  p_approver_device_id text,
  p_approver_secret text,
  p_target_device_id text,
  p_envelope jsonb
) returns void
language plpgsql security definer set search_path=public
as $$
declare v_user_id uuid:=auth.uid(); v_target public.brain_devices; v_envelope_id text;
begin
  if v_user_id is null then raise exception 'unauthenticated'; end if;
  if not public._brain_device_authorized_internal(v_user_id,p_vault_id,p_approver_device_id,p_approver_secret)
    then raise exception 'approver_not_authorized'; end if;

  select * into v_target from public.brain_devices d
  where d.user_id=v_user_id and d.vault_id=p_vault_id and d.device_id=p_target_device_id
  for update;
  if not found then raise exception 'target_device_not_found'; end if;
  if v_target.status<>'pending' then raise exception 'target_device_not_pending'; end if;

  if p_envelope->>'vault_id'<>p_vault_id
     or p_envelope->>'sender_device_id'<>p_approver_device_id
     or p_envelope->>'target_device_id'<>p_target_device_id then
    raise exception 'invalid_envelope_binding';
  end if;
  v_envelope_id:=p_envelope->>'envelope_id';
  if nullif(trim(v_envelope_id),'') is null then raise exception 'invalid_envelope_id'; end if;

  insert into public.brain_device_key_envelopes(
    user_id,vault_id,envelope_id,sender_device_id,target_device_id,payload
  ) values(v_user_id,p_vault_id,v_envelope_id,p_approver_device_id,p_target_device_id,p_envelope);

  update public.brain_devices
  set status='authorized',authorized_at=now(),revoked_at=null,last_seen_at=now()
  where user_id=v_user_id and vault_id=p_vault_id and device_id=p_target_device_id;
end;
$$;
grant execute on function public.approve_brain_device(text,text,text,text,jsonb) to authenticated;

create or replace function public.load_brain_device_envelope(
  p_vault_id text,p_target_device_id text,p_target_secret text
) returns jsonb
language plpgsql security definer set search_path=public
as $$
declare v_user_id uuid:=auth.uid(); v_payload jsonb;
begin
  if v_user_id is null then raise exception 'unauthenticated'; end if;
  if not public._brain_device_authorized_internal(v_user_id,p_vault_id,p_target_device_id,p_target_secret)
    then raise exception 'target_not_authorized'; end if;
  select e.payload into v_payload from public.brain_device_key_envelopes e
  where e.user_id=v_user_id and e.vault_id=p_vault_id
    and e.target_device_id=p_target_device_id and e.consumed_at is null
  order by e.created_at desc limit 1;
  return v_payload;
end;
$$;
grant execute on function public.load_brain_device_envelope(text,text,text) to authenticated;

create or replace function public.consume_brain_device_envelope(
  p_vault_id text,p_target_device_id text,p_target_secret text,p_envelope_id text
) returns void
language plpgsql security definer set search_path=public
as $$
declare v_user_id uuid:=auth.uid();
begin
  if v_user_id is null then raise exception 'unauthenticated'; end if;
  if not public._brain_device_authorized_internal(v_user_id,p_vault_id,p_target_device_id,p_target_secret)
    then raise exception 'target_not_authorized'; end if;
  update public.brain_device_key_envelopes set consumed_at=now()
  where user_id=v_user_id and vault_id=p_vault_id and target_device_id=p_target_device_id
    and envelope_id=p_envelope_id and consumed_at is null;
end;
$$;
grant execute on function public.consume_brain_device_envelope(text,text,text,text) to authenticated;

create or replace function public.revoke_brain_device(
  p_vault_id text,p_approver_device_id text,p_approver_secret text,p_target_device_id text
) returns void
language plpgsql security definer set search_path=public
as $$
declare v_user_id uuid:=auth.uid();
begin
  if v_user_id is null then raise exception 'unauthenticated'; end if;
  if p_approver_device_id=p_target_device_id then raise exception 'self_revoke_not_allowed'; end if;
  if not public._brain_device_authorized_internal(v_user_id,p_vault_id,p_approver_device_id,p_approver_secret)
    then raise exception 'approver_not_authorized'; end if;
  update public.brain_devices set status='revoked',revoked_at=now()
  where user_id=v_user_id and vault_id=p_vault_id and device_id=p_target_device_id and status<>'revoked';
  if not found then raise exception 'target_device_not_found'; end if;
end;
$$;
grant execute on function public.revoke_brain_device(text,text,text,text) to authenticated;

commit;
