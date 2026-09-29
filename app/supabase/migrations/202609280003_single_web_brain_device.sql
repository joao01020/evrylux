-- EVRYLUX Web: um único acesso Web por Vault.
--
-- Objetivos:
-- 1. permitir somente um EVRYLUX Web não-revogado por usuário/Vault;
-- 2. nova solicitação Web substitui a anterior;
-- 3. fingerprints antigos ficam revogados no banco para auditoria,
--    mas não aparecem mais na lista de dispositivos;
-- 4. Desktop/macOS/Linux não são afetados.
--
-- IMPORTANTE:
-- A substituição ocorre somente para device_name = 'EVRYLUX Web'.

begin;

-- Normaliza estado já existente: mantém somente o registro Web não-revogado
-- mais recente de cada usuário/Vault.
with ranked as (
  select
    id,
    row_number() over (
      partition by user_id, vault_id
      order by
        case status
          when 'pending' then 0
          when 'authorized' then 1
          else 2
        end,
        coalesce(last_seen_at, created_at) desc,
        created_at desc
    ) as rn
  from public.brain_devices
  where device_name = 'EVRYLUX Web'
    and status <> 'revoked'
),
to_revoke as (
  select id
  from ranked
  where rn > 1
)
update public.brain_devices d
set
  status = 'revoked',
  revoked_at = coalesce(d.revoked_at, now()),
  recovery_request_id = null,
  recovery_expires_at = null,
  last_seen_at = now()
from to_revoke r
where d.id = r.id;

-- Consome envelopes pendentes de registros Web que acabaram revogados.
update public.brain_device_key_envelopes e
set consumed_at = coalesce(e.consumed_at, now())
where e.consumed_at is null
  and exists (
    select 1
    from public.brain_devices d
    where d.user_id = e.user_id
      and d.vault_id = e.vault_id
      and d.device_id = e.target_device_id
      and d.device_name = 'EVRYLUX Web'
      and d.status = 'revoked'
  );

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
set search_path to 'public'
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

  -- Um único slot Web por usuário/Vault.
  --
  -- Quando chega uma NOVA identidade Web, qualquer identidade Web anterior
  -- perde acesso imediatamente. Isso também impede duas solicitações pending
  -- simultâneas.
  if trim(p_device_name) = 'EVRYLUX Web' then
    update public.brain_device_key_envelopes e
    set consumed_at = coalesce(e.consumed_at, now())
    where e.user_id = v_user_id
      and e.vault_id = trim(p_vault_id)
      and e.target_device_id in (
        select d.device_id
        from public.brain_devices d
        where d.user_id = v_user_id
          and d.vault_id = trim(p_vault_id)
          and d.device_name = 'EVRYLUX Web'
          and d.device_id <> trim(p_device_id)
          and d.status <> 'revoked'
      )
      and e.consumed_at is null;

    update public.brain_devices d
    set
      status = 'revoked',
      revoked_at = coalesce(d.revoked_at, now()),
      recovery_request_id = null,
      recovery_expires_at = null,
      last_seen_at = now()
    where d.user_id = v_user_id
      and d.vault_id = trim(p_vault_id)
      and d.device_name = 'EVRYLUX Web'
      and d.device_id <> trim(p_device_id)
      and d.status <> 'revoked';
  end if;

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
      set
        device_name = trim(p_device_name),
        last_seen_at = now()
      where id = v_existing.id
      returning * into v_row;
    else
      -- Reutiliza a solicitação pending enquanto ela ainda é válida.
      -- Isso evita trocar request_id a cada refresh.
      if v_existing.recovery_request_id is not null
         and v_existing.recovery_expires_at is not null
         and v_existing.recovery_expires_at > now() then
        update public.brain_devices
        set
          device_name = trim(p_device_name),
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
        set
          device_name = trim(p_device_name),
          recovery_request_id = v_request_id,
          recovery_expires_at = v_expires_at,
          last_seen_at = now()
        where id = v_existing.id
        returning * into v_row;
      end if;
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

create or replace function public.list_brain_devices(
  p_vault_id text,
  p_requester_device_id text,
  p_requester_secret text
) returns jsonb
language plpgsql
security definer
set search_path to 'public'
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
    and d.vault_id = trim(p_vault_id)
    -- Histórico Web revogado permanece no banco para auditoria,
    -- mas não polui a tela de dispositivos.
    and not (
      d.device_name = 'EVRYLUX Web'
      and d.status = 'revoked'
    );

  return v_result;
end;
$$;

revoke all on function public.register_brain_device(
  text, text, text, text, text, text
) from public;

grant execute on function public.register_brain_device(
  text, text, text, text, text, text
) to authenticated, service_role;

revoke all on function public.list_brain_devices(
  text, text, text
) from public;

grant execute on function public.list_brain_devices(
  text, text, text
) to authenticated, service_role;

commit;
