-- EVRYLUX Cérebro — Fase 3
-- Recuperação do device usando a Recovery Key criada na Fase 2.

begin;

create or replace function public.get_brain_recovery_package(
  p_vault_id text,
  p_device_id text,
  p_auth_secret text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_secret_hash bytea;
  v_package public.brain_recovery_packages;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if nullif(trim(p_vault_id), '') is null
     or nullif(trim(p_device_id), '') is null
     or nullif(trim(p_auth_secret), '') is null then
    raise exception 'invalid_recovery_request';
  end if;

  v_secret_hash := extensions.digest(
    convert_to(p_auth_secret, 'UTF8'),
    'sha256'
  );

  if not exists (
    select 1
    from public.brain_devices d
    where d.user_id = v_user_id
      and d.vault_id = trim(p_vault_id)
      and d.device_id = trim(p_device_id)
      and d.status in ('pending', 'authorized')
      and d.auth_secret_hash = v_secret_hash
  ) then
    raise exception 'device_identity_invalid';
  end if;

  select *
  into v_package
  from public.brain_recovery_packages r
  where r.user_id = v_user_id
    and r.vault_id = trim(p_vault_id);

  if not found then
    return null;
  end if;

  return jsonb_build_object(
    'vault_id', v_package.vault_id,
    'recovery_version', v_package.recovery_version,
    'key_version', v_package.key_version,
    'salt_b64', v_package.salt_b64,
    'nonce_b64', v_package.nonce_b64,
    'cipher_text_b64', v_package.cipher_text_b64,
    'mac_b64', v_package.mac_b64
  );
end;
$$;

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

  if not exists (
    select 1
    from public.brain_devices d
    where d.user_id = v_user_id
      and d.vault_id = trim(p_vault_id)
      and d.device_id = trim(p_device_id)
      and d.status in ('pending', 'authorized')
      and d.auth_secret_hash = v_secret_hash
  ) then
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

  update public.brain_devices
  set
    status = 'authorized',
    recovery_request_id = null,
    recovery_expires_at = null,
    authorized_at = coalesce(authorized_at, now()),
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

revoke all on function public.get_brain_recovery_package(text,text,text) from public;
revoke all on function public.get_brain_recovery_package(text,text,text) from anon;
grant execute on function public.get_brain_recovery_package(text,text,text) to authenticated;

revoke all on function public.authorize_brain_device_with_recovery_key(text,text,text,text) from public;
revoke all on function public.authorize_brain_device_with_recovery_key(text,text,text,text) from anon;
grant execute on function public.authorize_brain_device_with_recovery_key(text,text,text,text) to authenticated;

commit;
