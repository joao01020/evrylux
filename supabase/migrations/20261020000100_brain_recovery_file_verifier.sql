-- EVRYLUX Brain — recuperação por arquivo .evkey
--
-- O arquivo .evkey contém a Master Key protegida por senha.
-- O servidor NÃO recebe a Master Key.
--
-- Um dispositivo autorizado registra somente um verifier derivado
-- da Master Key. Na recuperação, o novo dispositivo prova posse
-- da mesma Master Key e então recebe status authorized.

begin;

create table if not exists public.brain_recovery_file_verifiers (
  user_id uuid not null references auth.users(id) on delete cascade,
  vault_id text not null,
  key_version integer not null,
  proof_hash bytea not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, vault_id)
);

alter table public.brain_recovery_file_verifiers enable row level security;

revoke all on table public.brain_recovery_file_verifiers from anon;
revoke all on table public.brain_recovery_file_verifiers from authenticated;

create or replace function public.save_brain_recovery_file_verifier(
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
  v_proof bytea;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if nullif(trim(p_vault_id), '') is null
     or nullif(trim(p_device_id), '') is null
     or nullif(trim(p_auth_secret), '') is null
     or p_key_version <= 0
     or nullif(trim(p_proof_hex), '') is null then
    raise exception 'invalid_recovery_file_verifier';
  end if;

  if length(trim(p_proof_hex)) <> 64
     or trim(p_proof_hex) !~ '^[0-9a-fA-F]{64}$' then
    raise exception 'invalid_recovery_file_proof';
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

  v_proof := decode(lower(trim(p_proof_hex)), 'hex');

  insert into public.brain_recovery_file_verifiers(
    user_id,
    vault_id,
    key_version,
    proof_hash,
    created_at,
    updated_at
  )
  values (
    v_user_id,
    trim(p_vault_id),
    p_key_version,
    extensions.digest(v_proof, 'sha256'),
    now(),
    now()
  )
  on conflict (user_id, vault_id)
  do update set
    key_version = excluded.key_version,
    proof_hash = excluded.proof_hash,
    updated_at = now();

  return true;
end;
$$;

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

revoke all on function public.save_brain_recovery_file_verifier(
  text,text,text,integer,text
) from public;
revoke all on function public.save_brain_recovery_file_verifier(
  text,text,text,integer,text
) from anon;
grant execute on function public.save_brain_recovery_file_verifier(
  text,text,text,integer,text
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

commit;
