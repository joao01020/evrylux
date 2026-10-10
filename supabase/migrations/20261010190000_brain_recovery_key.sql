begin;

create table if not exists public.brain_recovery_packages (
  user_id uuid not null references auth.users(id) on delete cascade,
  vault_id text not null,
  recovery_version integer not null,
  key_version integer not null,
  salt_b64 text not null,
  nonce_b64 text not null,
  cipher_text_b64 text not null,
  mac_b64 text not null,
  recovery_proof_hash bytea not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, vault_id)
);

alter table public.brain_recovery_packages enable row level security;

revoke all on table public.brain_recovery_packages from anon;
revoke all on table public.brain_recovery_packages from authenticated;

create or replace function public.brain_recovery_package_exists(
  p_vault_id text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if nullif(trim(p_vault_id), '') is null then
    return false;
  end if;

  return exists (
    select 1
    from public.brain_recovery_packages r
    where r.user_id = v_user_id
      and r.vault_id = trim(p_vault_id)
  );
end;
$$;

create or replace function public.save_brain_recovery_package(
  p_vault_id text,
  p_device_id text,
  p_auth_secret text,
  p_recovery_version integer,
  p_key_version integer,
  p_salt_b64 text,
  p_nonce_b64 text,
  p_cipher_text_b64 text,
  p_mac_b64 text,
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
  v_proof bytea;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if nullif(trim(p_vault_id), '') is null
     or nullif(trim(p_device_id), '') is null
     or nullif(trim(p_auth_secret), '') is null
     or p_recovery_version <= 0
     or p_key_version <= 0
     or nullif(trim(p_salt_b64), '') is null
     or nullif(trim(p_nonce_b64), '') is null
     or nullif(trim(p_cipher_text_b64), '') is null
     or nullif(trim(p_mac_b64), '') is null
     or nullif(trim(p_recovery_proof_hex), '') is null then
    raise exception 'invalid_recovery_package';
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
      and d.status = 'authorized'
      and d.auth_secret_hash = v_secret_hash
  ) then
    raise exception 'device_not_authorized';
  end if;

  v_proof := decode(lower(trim(p_recovery_proof_hex)), 'hex');

  insert into public.brain_recovery_packages(
    user_id,
    vault_id,
    recovery_version,
    key_version,
    salt_b64,
    nonce_b64,
    cipher_text_b64,
    mac_b64,
    recovery_proof_hash,
    created_at,
    updated_at
  )
  values (
    v_user_id,
    trim(p_vault_id),
    p_recovery_version,
    p_key_version,
    trim(p_salt_b64),
    trim(p_nonce_b64),
    trim(p_cipher_text_b64),
    trim(p_mac_b64),
    extensions.digest(v_proof, 'sha256'),
    now(),
    now()
  )
  on conflict (user_id, vault_id)
  do update set
    recovery_version = excluded.recovery_version,
    key_version = excluded.key_version,
    salt_b64 = excluded.salt_b64,
    nonce_b64 = excluded.nonce_b64,
    cipher_text_b64 = excluded.cipher_text_b64,
    mac_b64 = excluded.mac_b64,
    recovery_proof_hash = excluded.recovery_proof_hash,
    updated_at = now();

  return true;
end;
$$;

revoke all on function public.brain_recovery_package_exists(text) from public;
revoke all on function public.brain_recovery_package_exists(text) from anon;
grant execute on function public.brain_recovery_package_exists(text) to authenticated;

revoke all on function public.save_brain_recovery_package(
  text,text,text,integer,integer,text,text,text,text,text
) from public;
revoke all on function public.save_brain_recovery_package(
  text,text,text,integer,integer,text,text,text,text,text
) from anon;
grant execute on function public.save_brain_recovery_package(
  text,text,text,integer,integer,text,text,text,text,text
) to authenticated;

commit;
