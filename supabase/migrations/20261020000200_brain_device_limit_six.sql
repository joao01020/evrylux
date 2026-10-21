-- EVRYLUX Brain Devices — limite de 6 dispositivos
--
-- Esta migration NÃO edita migrations antigas já aplicadas.
-- Ela substitui os RPCs atuais para que:
--
-- 1. aprovação normal respeite no máximo 6 AUTHORIZED;
-- 2. Recovery Key textual respeite o mesmo limite;
-- 3. arquivo .evkey respeite o mesmo limite;
-- 4. advisory lock impeça duas recuperações/aprovações simultâneas
--    de ultrapassarem o limite;
-- 5. um dispositivo que JÁ está autorizado não seja bloqueado ao
--    revalidar a própria recuperação.
--
-- Pending não ocupa vaga. Revoked não ocupa vaga.

begin;

-- ============================================================
-- APPROVE DEVICE
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
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_target public.brain_devices;
  v_approver public.brain_devices;
  v_envelope_id text;
  v_payload_expires_at timestamptz;
  v_key_version integer;
  v_authorized_count integer;
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

  perform pg_advisory_xact_lock(
    hashtext(v_user_id::text || ':' || trim(p_vault_id))
  );

  if not public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_approver_device_id,
    p_approver_secret
  ) then
    raise exception 'approver_not_authorized';
  end if;

  select count(*)::integer
  into v_authorized_count
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id)
    and d.status = 'authorized';

  if v_authorized_count >= 6 then
    raise exception 'brain_device_limit_reached';
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
     or p_envelope->>'recovery_request_id' <> v_target.recovery_request_id::text
     or upper(p_envelope->>'target_key_fingerprint') <> upper(v_target.key_fingerprint)
     or p_envelope->>'sender_public_key_b64' <> v_approver.public_key_b64 then
    raise exception 'invalid_envelope_binding';
  end if;

  begin
    v_payload_expires_at := (p_envelope->>'expires_at')::timestamptz;
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

  v_envelope_id := nullif(trim(p_envelope->>'envelope_id'), '');

  if v_envelope_id is null then
    raise exception 'invalid_envelope_id';
  end if;

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

-- ============================================================
-- RECOVERY KEY TEXTUAL
-- ============================================================

create or replace function public.authorize_brain_device_with_recovery_key(
  p_vault_id text,
  p_device_id text,
  p_auth_secret text,
  p_recovery_proof_hex text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_secret_hash bytea;
  v_supplied_proof_hash bytea;
  v_expected_proof_hash bytea;
  v_authorized_count integer;
  v_target_status text;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if nullif(trim(p_vault_id), '') is null
     or nullif(trim(p_device_id), '') is null
     or nullif(trim(p_auth_secret), '') is null
     or nullif(trim(p_recovery_proof_hex), '') is null then
    raise exception 'invalid_recovery_request';
  end if;

  if length(trim(p_recovery_proof_hex)) <> 64
     or trim(p_recovery_proof_hex) !~ '^[0-9a-fA-F]{64}$' then
    raise exception 'invalid_recovery_proof';
  end if;

  v_secret_hash := extensions.digest(
    convert_to(p_auth_secret, 'UTF8'),
    'sha256'
  );

  perform pg_advisory_xact_lock(
    hashtext(v_user_id::text || ':' || trim(p_vault_id))
  );

  select d.status
  into v_target_status
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id)
    and d.device_id = trim(p_device_id)
    and d.status in ('pending', 'authorized')
    and d.auth_secret_hash = v_secret_hash
  for update;

  if not found then
    raise exception 'device_identity_invalid';
  end if;

  select r.recovery_proof_hash
  into v_expected_proof_hash
  from public.brain_recovery_packages r
  where r.user_id = v_user_id
    and r.vault_id = trim(p_vault_id);

  if v_expected_proof_hash is null then
    raise exception 'recovery_not_configured';
  end if;

  v_supplied_proof_hash := extensions.digest(
    decode(lower(trim(p_recovery_proof_hex)), 'hex'),
    'sha256'
  );

  if v_supplied_proof_hash <> v_expected_proof_hash then
    raise exception 'invalid_recovery_key';
  end if;

  if v_target_status <> 'authorized' then
    select count(*)::integer
    into v_authorized_count
    from public.brain_devices d
    where d.user_id = v_user_id
      and d.vault_id = trim(p_vault_id)
      and d.status = 'authorized';

    if v_authorized_count >= 6 then
      raise exception 'brain_device_limit_reached';
    end if;
  end if;

  update public.brain_devices
  set
    status = 'authorized',
    recovery_request_id = null,
    recovery_expires_at = null,
    authorized_at = coalesce(authorized_at, now()),
    revoked_at = null,
    last_seen_at = now()
  where user_id = v_user_id
    and vault_id = trim(p_vault_id)
    and device_id = trim(p_device_id)
    and auth_secret_hash = v_secret_hash;

  if not found then
    raise exception 'device_not_found';
  end if;

  return true;
end;
$$;

-- ============================================================
-- RECOVERY FILE .EVKEY
-- ============================================================

create or replace function public.authorize_brain_device_with_recovery_file(
  p_vault_id text,
  p_device_id text,
  p_auth_secret text,
  p_key_version integer,
  p_proof_hex text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_secret_hash bytea;
  v_expected_key_version integer;
  v_expected_proof_hash bytea;
  v_supplied_proof_hash bytea;
  v_authorized_count integer;
  v_target_status text;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if nullif(trim(p_vault_id), '') is null
     or nullif(trim(p_device_id), '') is null
     or nullif(trim(p_auth_secret), '') is null
     or p_key_version <= 0
     or nullif(trim(p_proof_hex), '') is null then
    raise exception 'invalid_recovery_file_request';
  end if;

  if length(trim(p_proof_hex)) <> 64
     or trim(p_proof_hex) !~ '^[0-9a-fA-F]{64}$' then
    raise exception 'invalid_recovery_file_proof';
  end if;

  v_secret_hash := extensions.digest(
    convert_to(p_auth_secret, 'UTF8'),
    'sha256'
  );

  perform pg_advisory_xact_lock(
    hashtext(v_user_id::text || ':' || trim(p_vault_id))
  );

  select d.status
  into v_target_status
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = trim(p_vault_id)
    and d.device_id = trim(p_device_id)
    and d.status in ('pending', 'authorized')
    and d.auth_secret_hash = v_secret_hash
  for update;

  if not found then
    raise exception 'device_identity_invalid';
  end if;

  select
    r.key_version,
    r.proof_hash
  into
    v_expected_key_version,
    v_expected_proof_hash
  from public.brain_recovery_file_verifiers r
  where r.user_id = v_user_id
    and r.vault_id = trim(p_vault_id);

  if v_expected_proof_hash is null then
    raise exception 'recovery_file_not_configured';
  end if;

  if v_expected_key_version <> p_key_version then
    raise exception 'recovery_file_key_version_mismatch';
  end if;

  v_supplied_proof_hash := extensions.digest(
    decode(lower(trim(p_proof_hex)), 'hex'),
    'sha256'
  );

  if v_supplied_proof_hash <> v_expected_proof_hash then
    raise exception 'invalid_recovery_file';
  end if;

  if v_target_status <> 'authorized' then
    select count(*)::integer
    into v_authorized_count
    from public.brain_devices d
    where d.user_id = v_user_id
      and d.vault_id = trim(p_vault_id)
      and d.status = 'authorized';

    if v_authorized_count >= 6 then
      raise exception 'brain_device_limit_reached';
    end if;
  end if;

  update public.brain_devices
  set
    status = 'authorized',
    recovery_request_id = null,
    recovery_expires_at = null,
    authorized_at = coalesce(authorized_at, now()),
    revoked_at = null,
    last_seen_at = now()
  where user_id = v_user_id
    and vault_id = trim(p_vault_id)
    and device_id = trim(p_device_id)
    and auth_secret_hash = v_secret_hash;

  if not found then
    raise exception 'device_not_found';
  end if;

  return true;
end;
$$;

-- Mantém permissões explícitas.

revoke all on function public.approve_brain_device(
  text,text,text,text,jsonb
) from public;
grant execute on function public.approve_brain_device(
  text,text,text,text,jsonb
) to authenticated, service_role;

revoke all on function public.authorize_brain_device_with_recovery_key(
  text,text,text,text
) from public;
revoke all on function public.authorize_brain_device_with_recovery_key(
  text,text,text,text
) from anon;
grant execute on function public.authorize_brain_device_with_recovery_key(
  text,text,text,text
) to authenticated;

revoke all on function public.authorize_brain_device_with_recovery_file(
  text,text,text,integer,text
) from public;
revoke all on function public.authorize_brain_device_with_recovery_file(
  text,text,text,integer,text
) from anon;
grant execute on function public.authorize_brain_device_with_recovery_file(
  text,text,text,integer,text
) to authenticated;

notify pgrst, 'reload schema';

commit;
