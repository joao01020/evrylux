begin;

create extension if not exists pgcrypto;

-- ============================================================
-- RECOVERY REQUEST BINDING + EXPIRATION
-- ============================================================

alter table public.brain_devices
  add column if not exists recovery_request_id uuid,
  add column if not exists recovery_expires_at timestamptz;

alter table public.brain_device_key_envelopes
  add column if not exists recovery_request_id uuid,
  add column if not exists expires_at timestamptz;

-- Legacy, unconsumed envelopes predate request binding.
-- Fail closed: they cannot be reused by the hardened protocol.
update public.brain_device_key_envelopes
set consumed_at = coalesce(consumed_at, now()),
    expires_at = coalesce(expires_at, now())
where recovery_request_id is null;

-- Existing pending rows receive a short-lived request. This is mostly
-- migration hygiene; users should create a fresh recovery request.
update public.brain_devices
set recovery_request_id = coalesce(recovery_request_id, gen_random_uuid()),
    recovery_expires_at = coalesce(recovery_expires_at, now() + interval '10 minutes')
where status = 'pending';

create unique index if not exists brain_device_envelope_request_unique
  on public.brain_device_key_envelopes(user_id, vault_id, recovery_request_id)
  where recovery_request_id is not null;

create index if not exists brain_device_pending_expiry_idx
  on public.brain_devices(user_id, vault_id, status, recovery_expires_at);

create index if not exists brain_device_envelope_claim_idx
  on public.brain_device_key_envelopes(
    user_id,
    vault_id,
    target_device_id,
    consumed_at,
    expires_at
  );

-- ============================================================
-- REMOVE DIRECT CLIENT TABLE ACCESS
-- ============================================================

drop policy if exists brain_devices_select_own on public.brain_devices;
drop policy if exists brain_device_key_envelopes_select_own
  on public.brain_device_key_envelopes;

revoke all on public.brain_devices from anon, authenticated;
revoke all on public.brain_device_key_envelopes from anon, authenticated;

-- ============================================================
-- INTERNAL AUTHORIZATION HELPER
-- ============================================================

create or replace function public._brain_device_authorized_internal(
  p_user_id uuid,
  p_vault_id text,
  p_device_id text,
  p_auth_secret text
) returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(
    select 1
    from public.brain_devices d
    where d.user_id = p_user_id
      and d.vault_id = trim(p_vault_id)
      and d.device_id = trim(p_device_id)
      and d.status = 'authorized'
      and d.auth_secret_hash =
          extensions.digest(
            convert_to(p_auth_secret, 'UTF8'),
            'sha256'
          )
  );
$$;

revoke all on function public._brain_device_authorized_internal(
  uuid,text,text,text
) from public, anon, authenticated;

-- ============================================================
-- REGISTER / CREATE RECOVERY REQUEST
-- ============================================================

create or replace function public.register_brain_device(
  p_device_id text,
  p_vault_id text,
  p_device_name text,
  p_public_key_b64 text,
  p_key_fingerprint text,
  p_auth_secret text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing public.brain_devices;
  v_row public.brain_devices;
  v_status text;
  v_request_id uuid;
  v_expires_at timestamptz;
  v_secret_hash bytea;
  v_any_row boolean;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if nullif(trim(p_device_id), '') is null
     or nullif(trim(p_vault_id), '') is null
     or nullif(trim(p_device_name), '') is null
     or nullif(trim(p_public_key_b64), '') is null
     or nullif(trim(p_key_fingerprint), '') is null
     or nullif(trim(p_auth_secret), '') is null then
    raise exception 'invalid_device_registration';
  end if;

  if length(trim(p_device_id)) > 200
     or length(trim(p_vault_id)) > 300
     or length(trim(p_device_name)) > 160
     or length(trim(p_public_key_b64)) > 256
     or length(trim(p_key_fingerprint)) > 128
     or length(trim(p_auth_secret)) > 512 then
    raise exception 'device_registration_too_large';
  end if;

  v_secret_hash :=
    extensions.digest(
      convert_to(p_auth_secret, 'UTF8'),
      'sha256'
    );

  perform pg_advisory_xact_lock(
    hashtext(v_user_id::text || ':' || trim(p_vault_id))
  );

  select *
  into v_existing
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id)
    and d.device_id = trim(p_device_id)
  for update;

  if found then
    if v_existing.auth_secret_hash <> v_secret_hash
       or v_existing.public_key_b64 <> trim(p_public_key_b64)
       or upper(v_existing.key_fingerprint) <>
          upper(trim(p_key_fingerprint)) then
      raise exception 'device_identity_mismatch';
    end if;

    if v_existing.status = 'revoked' then
      raise exception 'device_revoked';
    end if;

    if v_existing.status = 'authorized' then
      update public.brain_devices
      set device_name = trim(p_device_name),
          last_seen_at = now()
      where id = v_existing.id
      returning * into v_row;
    else
      v_request_id := gen_random_uuid();
      v_expires_at := now() + interval '10 minutes';

      update public.brain_device_key_envelopes
      set consumed_at = coalesce(consumed_at, now())
      where user_id = v_user_id
        and vault_id = trim(p_vault_id)
        and target_device_id = trim(p_device_id)
        and consumed_at is null;

      update public.brain_devices
      set device_name = trim(p_device_name),
          recovery_request_id = v_request_id,
          recovery_expires_at = v_expires_at,
          last_seen_at = now()
      where id = v_existing.id
      returning * into v_row;
    end if;
  else
    select exists(
      select 1
      from public.brain_devices d
      where d.user_id = v_user_id
        and d.vault_id = trim(p_vault_id)
    ) into v_any_row;

    if v_any_row then
      v_status := 'pending';
      v_request_id := gen_random_uuid();
      v_expires_at := now() + interval '10 minutes';
    else
      -- Bootstrap is allowed only when this vault has never had a device.
      -- Revoking every device does NOT reopen bootstrap.
      v_status := 'authorized';
      v_request_id := null;
      v_expires_at := null;
    end if;

    insert into public.brain_devices(
      user_id,
      vault_id,
      device_id,
      device_name,
      public_key_b64,
      key_fingerprint,
      auth_secret_hash,
      status,
      recovery_request_id,
      recovery_expires_at,
      authorized_at,
      last_seen_at
    ) values (
      v_user_id,
      trim(p_vault_id),
      trim(p_device_id),
      trim(p_device_name),
      trim(p_public_key_b64),
      upper(trim(p_key_fingerprint)),
      v_secret_hash,
      v_status,
      v_request_id,
      v_expires_at,
      case when v_status = 'authorized' then now() else null end,
      now()
    )
    returning * into v_row;
  end if;

  return jsonb_build_object(
    'device_id', v_row.device_id,
    'vault_id', v_row.vault_id,
    'device_name', v_row.device_name,
    'public_key_b64', v_row.public_key_b64,
    'key_fingerprint', v_row.key_fingerprint,
    'status', v_row.status,
    'created_at', v_row.created_at,
    'authorized_at', v_row.authorized_at,
    'revoked_at', v_row.revoked_at,
    'last_seen_at', v_row.last_seen_at,
    'recovery_request_id', v_row.recovery_request_id,
    'recovery_expires_at', v_row.recovery_expires_at
  );
end;
$$;

revoke all on function public.register_brain_device(
  text,text,text,text,text,text
) from public, anon;
grant execute on function public.register_brain_device(
  text,text,text,text,text,text
) to authenticated;

-- ============================================================
-- AUTHORIZED DEVICE CHECK
-- ============================================================

create or replace function public.brain_device_is_authorized(
  p_vault_id text,
  p_device_id text,
  p_auth_secret text
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_ok boolean;
begin
  if v_user_id is null then
    return false;
  end if;

  v_ok := public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_device_id,
    p_auth_secret
  );

  if v_ok then
    update public.brain_devices
    set last_seen_at = now()
    where user_id = v_user_id
      and vault_id = trim(p_vault_id)
      and device_id = trim(p_device_id);
  end if;

  return v_ok;
end;
$$;

revoke all on function public.brain_device_is_authorized(
  text,text,text
) from public, anon;
grant execute on function public.brain_device_is_authorized(
  text,text,text
) to authenticated;

-- ============================================================
-- LIST / GET THROUGH AN AUTHORIZED DEVICE ONLY
-- ============================================================

create or replace function public.list_brain_devices(
  p_vault_id text,
  p_requester_device_id text,
  p_requester_secret text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if not public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_requester_device_id,
    p_requester_secret
  ) then
    raise exception 'requester_not_authorized';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'device_id', d.device_id,
        'vault_id', d.vault_id,
        'device_name', d.device_name,
        'public_key_b64', d.public_key_b64,
        'key_fingerprint', d.key_fingerprint,
        'status', d.status,
        'created_at', d.created_at,
        'authorized_at', d.authorized_at,
        'revoked_at', d.revoked_at,
        'last_seen_at', d.last_seen_at,
        'recovery_request_id', d.recovery_request_id,
        'recovery_expires_at', d.recovery_expires_at
      )
      order by d.created_at asc
    ),
    '[]'::jsonb
  )
  into v_result
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id);

  return v_result;
end;
$$;

revoke all on function public.list_brain_devices(
  text,text,text
) from public, anon;
grant execute on function public.list_brain_devices(
  text,text,text
) to authenticated;

create or replace function public.get_brain_device(
  p_vault_id text,
  p_requester_device_id text,
  p_requester_secret text,
  p_target_device_id text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_target public.brain_devices;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if not public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_requester_device_id,
    p_requester_secret
  ) then
    raise exception 'requester_not_authorized';
  end if;

  select *
  into v_target
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id)
    and d.device_id = trim(p_target_device_id);

  if not found then
    return null;
  end if;

  return jsonb_build_object(
    'device_id', v_target.device_id,
    'vault_id', v_target.vault_id,
    'device_name', v_target.device_name,
    'public_key_b64', v_target.public_key_b64,
    'key_fingerprint', v_target.key_fingerprint,
    'status', v_target.status,
    'created_at', v_target.created_at,
    'authorized_at', v_target.authorized_at,
    'revoked_at', v_target.revoked_at,
    'last_seen_at', v_target.last_seen_at,
    'recovery_request_id', v_target.recovery_request_id,
    'recovery_expires_at', v_target.recovery_expires_at
  );
end;
$$;

revoke all on function public.get_brain_device(
  text,text,text,text
) from public, anon;
grant execute on function public.get_brain_device(
  text,text,text,text
) to authenticated;

-- ============================================================
-- APPROVE: SERVER VALIDATES ALL RECOVERY BINDINGS
-- ============================================================

create or replace function public.approve_brain_device(
  p_vault_id text,
  p_approver_device_id text,
  p_approver_secret text,
  p_target_device_id text,
  p_envelope jsonb
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_target public.brain_devices;
  v_approver public.brain_devices;
  v_envelope_id text;
  v_payload_expires_at timestamptz;
  v_key_version integer;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if p_approver_device_id = p_target_device_id then
    raise exception 'self_approval_not_allowed';
  end if;

  if octet_length(p_envelope::text) > 16384 then
    raise exception 'envelope_too_large';
  end if;

  if not public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_approver_device_id,
    p_approver_secret
  ) then
    raise exception 'approver_not_authorized';
  end if;

  select *
  into v_approver
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id)
    and d.device_id = trim(p_approver_device_id)
  for share;

  select *
  into v_target
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id)
    and d.device_id = trim(p_target_device_id)
  for update;

  if not found then
    raise exception 'target_device_not_found';
  end if;

  if v_target.status <> 'pending' then
    raise exception 'target_device_not_pending';
  end if;

  if v_target.recovery_request_id is null
     or v_target.recovery_expires_at is null then
    raise exception 'recovery_binding_missing';
  end if;

  if v_target.recovery_expires_at <= now() then
    raise exception 'recovery_request_expired';
  end if;

  if p_envelope->>'vault_id' <> trim(p_vault_id)
     or p_envelope->>'sender_device_id' <> trim(p_approver_device_id)
     or p_envelope->>'target_device_id' <> trim(p_target_device_id)
     or p_envelope->>'recovery_request_id' <>
        v_target.recovery_request_id::text
     or upper(p_envelope->>'target_key_fingerprint') <>
        upper(v_target.key_fingerprint)
     or p_envelope->>'sender_public_key_b64' <>
        v_approver.public_key_b64 then
    raise exception 'invalid_envelope_binding';
  end if;

  begin
    v_payload_expires_at :=
      (p_envelope->>'expires_at')::timestamptz;
  exception when others then
    raise exception 'invalid_envelope_expiry';
  end;

  if v_payload_expires_at <> v_target.recovery_expires_at then
    raise exception 'invalid_envelope_expiry_binding';
  end if;

  begin
    v_key_version := (p_envelope->>'key_version')::integer;
  exception when others then
    raise exception 'invalid_key_version';
  end;

  if v_key_version <= 0 then
    raise exception 'invalid_key_version';
  end if;

  v_envelope_id := nullif(
    trim(p_envelope->>'envelope_id'),
    ''
  );

  if v_envelope_id is null then
    raise exception 'invalid_envelope_id';
  end if;

  -- Only one live envelope per device/request.
  update public.brain_device_key_envelopes
  set consumed_at = coalesce(consumed_at, now())
  where user_id = v_user_id
    and vault_id = trim(p_vault_id)
    and target_device_id = trim(p_target_device_id)
    and consumed_at is null;

  insert into public.brain_device_key_envelopes(
    user_id,
    vault_id,
    envelope_id,
    sender_device_id,
    target_device_id,
    recovery_request_id,
    expires_at,
    payload
  ) values (
    v_user_id,
    trim(p_vault_id),
    v_envelope_id,
    trim(p_approver_device_id),
    trim(p_target_device_id),
    v_target.recovery_request_id,
    v_target.recovery_expires_at,
    p_envelope
  );

  update public.brain_devices
  set status = 'authorized',
      authorized_at = now(),
      revoked_at = null,
      last_seen_at = now()
  where id = v_target.id;
end;
$$;

revoke all on function public.approve_brain_device(
  text,text,text,text,jsonb
) from public, anon;
grant execute on function public.approve_brain_device(
  text,text,text,text,jsonb
) to authenticated;

-- ============================================================
-- CLAIM + CONSUME ATOMICALLY
-- ============================================================

create or replace function public.claim_brain_device_envelope(
  p_vault_id text,
  p_target_device_id text,
  p_target_secret text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_device public.brain_devices;
  v_envelope public.brain_device_key_envelopes;
  v_payload jsonb;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if not public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_target_device_id,
    p_target_secret
  ) then
    raise exception 'target_not_authorized';
  end if;

  select *
  into v_device
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id)
    and d.device_id = trim(p_target_device_id)
  for update;

  if v_device.recovery_request_id is null then
    return null;
  end if;

  select *
  into v_envelope
  from public.brain_device_key_envelopes e
  where e.user_id = v_user_id
    and e.vault_id = trim(p_vault_id)
    and e.target_device_id = trim(p_target_device_id)
    and e.recovery_request_id = v_device.recovery_request_id
    and e.consumed_at is null
    and e.expires_at > now()
  order by e.created_at desc
  limit 1
  for update;

  if not found then
    return null;
  end if;

  update public.brain_device_key_envelopes
  set consumed_at = now()
  where id = v_envelope.id
    and consumed_at is null
  returning payload into v_payload;

  if v_payload is null then
    return null;
  end if;

  -- Closing the request prevents a second envelope from being claimed.
  update public.brain_devices
  set recovery_request_id = null,
      recovery_expires_at = null,
      last_seen_at = now()
  where id = v_device.id;

  return v_payload;
end;
$$;

revoke all on function public.claim_brain_device_envelope(
  text,text,text
) from public, anon;
grant execute on function public.claim_brain_device_envelope(
  text,text,text
) to authenticated;

-- Disable legacy two-step RPCs so a client cannot bypass atomic claim.
revoke all on function public.load_brain_device_envelope(
  text,text,text
) from public, anon, authenticated;

revoke all on function public.consume_brain_device_envelope(
  text,text,text,text
) from public, anon, authenticated;

-- ============================================================
-- REVOKE
-- ============================================================

create or replace function public.revoke_brain_device(
  p_vault_id text,
  p_approver_device_id text,
  p_approver_secret text,
  p_target_device_id text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_target_id uuid;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if p_approver_device_id = p_target_device_id then
    raise exception 'self_revoke_not_allowed';
  end if;

  if not public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_approver_device_id,
    p_approver_secret
  ) then
    raise exception 'approver_not_authorized';
  end if;

  select d.id
  into v_target_id
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id)
    and d.device_id = trim(p_target_device_id)
  for update;

  if not found then
    raise exception 'target_device_not_found';
  end if;

  update public.brain_device_key_envelopes
  set consumed_at = coalesce(consumed_at, now())
  where user_id = v_user_id
    and vault_id = trim(p_vault_id)
    and target_device_id = trim(p_target_device_id)
    and consumed_at is null;

  update public.brain_devices
  set status = 'revoked',
      revoked_at = now(),
      recovery_request_id = null,
      recovery_expires_at = null
  where id = v_target_id;
end;
$$;

revoke all on function public.revoke_brain_device(
  text,text,text,text
) from public, anon;
grant execute on function public.revoke_brain_device(
  text,text,text,text
) to authenticated;

commit;
