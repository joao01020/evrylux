


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."_brain_device_authorized_internal"("p_user_id" "uuid", "p_vault_id" "text", "p_device_id" "text", "p_auth_secret" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."_brain_device_authorized_internal"("p_user_id" "uuid", "p_vault_id" "text", "p_device_id" "text", "p_auth_secret" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."approve_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text", "p_envelope" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."approve_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text", "p_envelope" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."brain_device_is_authorized"("p_vault_id" "text", "p_device_id" "text", "p_auth_secret" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."brain_device_is_authorized"("p_vault_id" "text", "p_device_id" "text", "p_auth_secret" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."claim_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."claim_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."consume_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text", "p_envelope_id" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."consume_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text", "p_envelope_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."disconnect_current_user_device"() RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$

declare

  v_user_id uuid :=
    auth.uid();

  v_session_id_text text :=
    auth.jwt() ->> 'session_id';

  v_session_id uuid;

  v_rows integer :=
    0;

begin

  if v_user_id is null then

    return false;

  end if;


  if v_session_id_text is null
      or length(
        trim(
          v_session_id_text
        )
      ) = 0 then

    return false;

  end if;


  v_session_id :=
    v_session_id_text::uuid;


  update public.user_devices

  set ended_at =
    coalesce(
      ended_at,
      now()
    )

  where user_id =
          v_user_id

    and session_id =
          v_session_id

    and ended_at
          is null;


  get diagnostics
    v_rows =
      row_count;


  return v_rows = 1;

end;

$$;


ALTER FUNCTION "public"."disconnect_current_user_device"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_brain_device"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text", "p_target_device_id" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."get_brain_device"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text", "p_target_device_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_routine_owner"("p_routine_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
    select exists (
        select 1
        from public.routines r
        where r.id = p_routine_id
          and r.user_id = auth.uid()
    );
$$;


ALTER FUNCTION "public"."is_routine_owner"("p_routine_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."list_brain_devices"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."list_brain_devices"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."load_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."load_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."register_brain_device"("p_device_id" "text", "p_vault_id" "text", "p_device_name" "text", "p_public_key_b64" "text", "p_key_fingerprint" "text", "p_auth_secret" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."register_brain_device"("p_device_id" "text", "p_vault_id" "text", "p_device_name" "text", "p_public_key_b64" "text", "p_key_fingerprint" "text", "p_auth_secret" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."register_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$

declare

  v_user_id uuid :=
    auth.uid();

  v_session_id_text text :=
    auth.jwt() ->> 'session_id';

  v_session_id uuid;

  v_active boolean :=
    false;

begin

  -- ==========================================================
  -- AUTH
  -- ==========================================================

  if v_user_id is null then

    raise exception
      'Usuário não autenticado.';

  end if;


  -- ==========================================================
  -- SESSION
  -- ==========================================================

  if v_session_id_text is null
      or length(
        trim(
          v_session_id_text
        )
      ) = 0 then

    raise exception
      'Sessão sem session_id.';

  end if;


  v_session_id :=
    v_session_id_text::uuid;


  -- ==========================================================
  -- DEVICE ID
  -- ==========================================================

  if p_device_id is null
      or length(
        trim(
          p_device_id
        )
      ) = 0 then

    raise exception
      'device_id inválido.';

  end if;


  -- ==========================================================
  -- DEVICE NAME
  -- ==========================================================

  if p_device_name is null
      or length(
        trim(
          p_device_name
        )
      ) = 0 then

    raise exception
      'device_name inválido.';

  end if;


  -- ==========================================================
  -- PLATFORM
  -- ==========================================================

  if p_platform is null
      or length(
        trim(
          p_platform
        )
      ) = 0 then

    raise exception
      'platform inválido.';

  end if;


  -- ==========================================================
  -- UPSERT CURRENT SESSION
  -- ==========================================================

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

    trim(
      p_device_id
    ),

    trim(
      p_device_name
    ),

    trim(
      p_platform
    ),

    nullif(
      trim(
        coalesce(
          p_app_version,
          ''
        )
      ),
      ''
    ),

    now()

  )

  on conflict (
    user_id,
    session_id
  )

  do update

  set

    device_id =
      excluded.device_id,

    device_name =
      excluded.device_name,

    platform =
      excluded.platform,

    app_version =
      excluded.app_version,

    last_seen_at =
      now()

  where public.user_devices.revoked_at
          is null

    and public.user_devices.ended_at
          is null;


  -- ==========================================================
  -- CHECK ACTIVE
  -- ==========================================================

  select (

    d.revoked_at is null

    and

    d.ended_at is null

  )

  into v_active

  from public.user_devices as d

  where d.user_id =
          v_user_id

    and d.session_id =
          v_session_id

  limit 1;


  return coalesce(
    v_active,
    false
  );

end;

$$;


ALTER FUNCTION "public"."register_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."revoke_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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


ALTER FUNCTION "public"."revoke_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."revoke_user_device"("p_session_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$

declare

  v_user_id uuid :=
    auth.uid();

  v_current_session_id_text text :=
    auth.jwt() ->> 'session_id';

  v_current_session_id uuid;

  v_rows integer :=
    0;

begin

  if v_user_id is null then

    raise exception
      'Usuário não autenticado.';

  end if;


  if v_current_session_id_text is null
      or length(
        trim(
          v_current_session_id_text
        )
      ) = 0 then

    raise exception
      'Sessão sem session_id.';

  end if;


  v_current_session_id :=
    v_current_session_id_text::uuid;


  if p_session_id =
      v_current_session_id then

    raise exception
      'Não é permitido revogar a sessão atual por esta função.';

  end if;


  update public.user_devices

  set revoked_at =
    coalesce(
      revoked_at,
      now()
    )

  where user_id =
          v_user_id

    and session_id =
          p_session_id

    and revoked_at
          is null

    and ended_at
          is null;


  get diagnostics
    v_rows =
      row_count;


  return v_rows = 1;

end;

$$;


ALTER FUNCTION "public"."revoke_user_device"("p_session_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_app_updates_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
    new.updated_at = now();

    return new;
end;
$$;


ALTER FUNCTION "public"."set_app_updates_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_telegram_connection_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_telegram_connection_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
    new.updated_at = now();

    return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."sync_task_completed_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin

    if new.is_completed = true
       and old.is_completed = false then

        new.completed_at = now();

    elsif new.is_completed = false
          and old.is_completed = true then

        new.completed_at = null;

    end if;

    return new;

end;
$$;


ALTER FUNCTION "public"."sync_task_completed_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."touch_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text" DEFAULT NULL::"text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$

declare

  v_user_id uuid :=
    auth.uid();

  v_session_id_text text :=
    auth.jwt() ->> 'session_id';

  v_session_id uuid;

  v_rows integer :=
    0;

begin

  if v_user_id is null then

    raise exception
      'Usuário não autenticado.';

  end if;


  if v_session_id_text is null
      or length(
        trim(
          v_session_id_text
        )
      ) = 0 then

    raise exception
      'Sessão sem session_id.';

  end if;


  v_session_id :=
    v_session_id_text::uuid;


  update public.user_devices

  set

    device_id =
      trim(
        p_device_id
      ),

    device_name =
      trim(
        p_device_name
      ),

    platform =
      trim(
        p_platform
      ),

    app_version =
      nullif(
        trim(
          coalesce(
            p_app_version,
            ''
          )
        ),
        ''
      ),

    last_seen_at =
      now()

  where user_id =
          v_user_id

    and session_id =
          v_session_id

    and revoked_at
          is null

    and ended_at
          is null;


  get diagnostics
    v_rows =
      row_count;


  return v_rows = 1;

end;

$$;


ALTER FUNCTION "public"."touch_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_routine_comments_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
begin
    new.updated_at = now();

    return new;
end;
$$;


ALTER FUNCTION "public"."update_routine_comments_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_brain_object_e2ee"("p_vault_id" "text", "p_object_id" "text", "p_object_version" integer, "p_crypto_version" integer, "p_key_version" integer, "p_is_deleted" boolean, "p_encrypted_object" "jsonb", "p_created_at" timestamp with time zone, "p_updated_at" timestamp with time zone) RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO 'public'
    AS $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_vault_id is null
     or btrim(p_vault_id) = '' then
    raise exception 'invalid_vault_id';
  end if;

  if p_object_id is null
     or btrim(p_object_id) = '' then
    raise exception 'invalid_object_id';
  end if;

  if p_object_version <= 0
     or p_crypto_version <= 0
     or p_key_version <= 0 then
    raise exception 'invalid_version';
  end if;

  if p_encrypted_object is null then
    raise exception 'encrypted_object_required';
  end if;

  insert into public.brain_objects (
    user_id,
    vault_id,
    object_id,
    object_version,
    crypto_version,
    key_version,
    is_deleted,
    encrypted_object,
    created_at,
    updated_at,
    server_updated_at
  )
  values (
    v_user_id,
    p_vault_id,
    p_object_id,
    p_object_version,
    p_crypto_version,
    p_key_version,
    p_is_deleted,
    p_encrypted_object,
    p_created_at,
    p_updated_at,
    now()
  )
  on conflict (
    user_id,
    vault_id,
    object_id
  )
  do update set
    object_version =
      excluded.object_version,
    crypto_version =
      excluded.crypto_version,
    key_version =
      excluded.key_version,
    is_deleted =
      excluded.is_deleted,
    encrypted_object =
      excluded.encrypted_object,
    created_at =
      least(
        public.brain_objects.created_at,
        excluded.created_at
      ),
    updated_at =
      excluded.updated_at,
    server_updated_at =
      now()
  where
    public.brain_objects.object_version
      <= excluded.object_version;
end;
$$;


ALTER FUNCTION "public"."upsert_brain_object_e2ee"("p_vault_id" "text", "p_object_id" "text", "p_object_version" integer, "p_crypto_version" integer, "p_key_version" integer, "p_is_deleted" boolean, "p_encrypted_object" "jsonb", "p_created_at" timestamp with time zone, "p_updated_at" timestamp with time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_brain_concept_owner"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  note_owner uuid;
begin
  if new.note_id is null then
    return new;
  end if;

  select user_id
  into note_owner
  from public.brain_notes
  where id = new.note_id;

  if note_owner is null then
    raise exception 'Brain note not found.';
  end if;

  if note_owner <> new.user_id then
    raise exception 'Brain note belongs to another user.';
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."validate_brain_concept_owner"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_brain_review_owner"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  concept_owner uuid;
begin
  select user_id
  into concept_owner
  from public.brain_concepts
  where id = new.concept_id;

  if concept_owner is null then
    raise exception 'Brain concept not found.';
  end if;

  if concept_owner <> new.user_id then
    raise exception 'Brain concept belongs to another user.';
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."validate_brain_review_owner"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."app_updates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "version" "text" NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "download_url" "text",
    "active" boolean DEFAULT true NOT NULL,
    "published_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "app_updates_message_not_empty" CHECK (("length"(TRIM(BOTH FROM "message")) > 0)),
    CONSTRAINT "app_updates_title_not_empty" CHECK (("length"(TRIM(BOTH FROM "title")) > 0)),
    CONSTRAINT "app_updates_version_not_empty" CHECK (("length"(TRIM(BOTH FROM "version")) > 0))
);


ALTER TABLE "public"."app_updates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_updates_test" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "version" "text" NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "download_url" "text",
    "active" boolean DEFAULT false NOT NULL,
    "published_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."app_updates_test" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."board_attachments" (
    "id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "board_id" "text" NOT NULL,
    "block_id" "text" NOT NULL,
    "file_name" "text" NOT NULL,
    "type" "text" DEFAULT 'unknown'::"text" NOT NULL,
    "remote_path" "text",
    "mime_type" "text",
    "size_bytes" bigint DEFAULT 0 NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "board_attachments_type_check" CHECK (("type" = ANY (ARRAY['markdown'::"text", 'text'::"text", 'unknown'::"text"])))
);


ALTER TABLE "public"."board_attachments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."brain_concepts" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "note_id" "uuid",
    "title" "text" NOT NULL,
    "description" "text" NOT NULL,
    "type" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "brain_concepts_type_check" CHECK (("type" = ANY (ARRAY['concept'::"text", 'question'::"text", 'example'::"text", 'warning'::"text"])))
);


ALTER TABLE "public"."brain_concepts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."brain_device_key_envelopes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "vault_id" "text" NOT NULL,
    "envelope_id" "text" NOT NULL,
    "sender_device_id" "text" NOT NULL,
    "target_device_id" "text" NOT NULL,
    "payload" "jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "consumed_at" timestamp with time zone,
    "recovery_request_id" "uuid",
    "expires_at" timestamp with time zone
);


ALTER TABLE "public"."brain_device_key_envelopes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."brain_devices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "vault_id" "text" NOT NULL,
    "device_id" "text" NOT NULL,
    "device_name" "text" NOT NULL,
    "public_key_b64" "text" NOT NULL,
    "key_fingerprint" "text" NOT NULL,
    "auth_secret_hash" "bytea" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "authorized_at" timestamp with time zone,
    "revoked_at" timestamp with time zone,
    "last_seen_at" timestamp with time zone,
    "recovery_request_id" "uuid",
    "recovery_expires_at" timestamp with time zone,
    CONSTRAINT "brain_devices_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'authorized'::"text", 'revoked'::"text"])))
);


ALTER TABLE "public"."brain_devices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."brain_notes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "topic" "text" NOT NULL,
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."brain_notes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."brain_objects" (
    "user_id" "uuid" NOT NULL,
    "vault_id" "text" NOT NULL,
    "object_id" "text" NOT NULL,
    "object_version" integer NOT NULL,
    "crypto_version" integer NOT NULL,
    "key_version" integer NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL,
    "encrypted_object" "jsonb" NOT NULL,
    "created_at" timestamp with time zone NOT NULL,
    "updated_at" timestamp with time zone NOT NULL,
    "server_updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "brain_objects_crypto_version_check" CHECK (("crypto_version" > 0)),
    CONSTRAINT "brain_objects_key_version_check" CHECK (("key_version" > 0)),
    CONSTRAINT "brain_objects_object_version_check" CHECK (("object_version" > 0))
);


ALTER TABLE "public"."brain_objects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."brain_reviews" (
    "id" "text" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "concept_id" "text" NOT NULL,
    "question" "text" NOT NULL,
    "answer" "text" NOT NULL,
    "source_note_path" "text" DEFAULT ''::"text" NOT NULL,
    "source_note_title" "text" DEFAULT ''::"text" NOT NULL,
    "next_review_at" timestamp with time zone NOT NULL,
    "last_reviewed_at" timestamp with time zone,
    "review_count" integer DEFAULT 0 NOT NULL,
    "correct_count" integer DEFAULT 0 NOT NULL,
    "wrong_count" integer DEFAULT 0 NOT NULL,
    "streak" integer DEFAULT 0 NOT NULL,
    "archived" boolean DEFAULT false NOT NULL,
    "archived_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "brain_reviews_correct_count_check" CHECK (("correct_count" >= 0)),
    CONSTRAINT "brain_reviews_review_count_check" CHECK (("review_count" >= 0)),
    CONSTRAINT "brain_reviews_streak_check" CHECK (("streak" >= 0)),
    CONSTRAINT "brain_reviews_wrong_count_check" CHECK (("wrong_count" >= 0))
);


ALTER TABLE "public"."brain_reviews" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."content_blocks" (
    "block_id" "uuid" NOT NULL,
    "content" "text" DEFAULT ''::"text" NOT NULL,
    "content_type" "text" DEFAULT 'text'::"text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."content_blocks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_contributions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "value" double precision DEFAULT 0 NOT NULL,
    "contribution_date" timestamp with time zone DEFAULT "now"() NOT NULL,
    "rhythm" "text" DEFAULT 'Personalizado'::"text" NOT NULL,
    "objective_progress" double precision DEFAULT 0 NOT NULL,
    "time_progress" double precision DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."finance_contributions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_data" (
    "user_id" "uuid" NOT NULL,
    "patrimony" double precision DEFAULT 0 NOT NULL,
    "invested" double precision DEFAULT 0 NOT NULL,
    "monthly_goal" double precision DEFAULT 0 NOT NULL,
    "investment_goal" double precision DEFAULT 0 NOT NULL,
    "minimum_goal" double precision DEFAULT 0 NOT NULL,
    "medium_goal" double precision DEFAULT 0 NOT NULL,
    "maximum_goal" double precision DEFAULT 0 NOT NULL,
    "projection_years" integer DEFAULT 10 NOT NULL,
    "total_invested" double precision DEFAULT 0 NOT NULL,
    "invested_months" integer DEFAULT 0 NOT NULL,
    "average_contribution" double precision DEFAULT 0 NOT NULL,
    "bitcoin" double precision DEFAULT 0 NOT NULL,
    "ethereum" double precision DEFAULT 0 NOT NULL,
    "solana" double precision DEFAULT 0 NOT NULL,
    "usdt" double precision DEFAULT 0 NOT NULL,
    "completed_days" boolean[] DEFAULT ARRAY[false, false, false, false, false, false, false] NOT NULL,
    "selected_day" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."finance_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."finance_objectives" (
    "user_id" "uuid" NOT NULL,
    "name" "text" DEFAULT 'Objetivo financeiro'::"text" NOT NULL,
    "target_value" numeric(14,2) DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."finance_objectives" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."journey_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "date" "text" NOT NULL,
    "notes" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."journey_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mind_map_blocks" (
    "block_id" "uuid" NOT NULL,
    "zoom" double precision DEFAULT 1.0 NOT NULL,
    "offset_x" double precision DEFAULT 0 NOT NULL,
    "offset_y" double precision DEFAULT 0 NOT NULL,
    "background_type" "text" DEFAULT 'plain'::"text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."mind_map_blocks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mind_map_connections" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "mind_map_block_id" "uuid" NOT NULL,
    "source_node_id" "uuid" NOT NULL,
    "target_node_id" "uuid" NOT NULL,
    "source_port_id" "uuid",
    "target_port_id" "uuid",
    "label" "text",
    "connection_type" "text" DEFAULT 'curve'::"text" NOT NULL,
    "color" "text",
    "stroke_width" double precision DEFAULT 2 NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "mind_map_connections_check" CHECK (("source_node_id" <> "target_node_id"))
);


ALTER TABLE "public"."mind_map_connections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mind_map_nodes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "mind_map_block_id" "uuid",
    "title" "text" DEFAULT 'Novo nó'::"text" NOT NULL,
    "content" "text",
    "x" double precision DEFAULT 0 NOT NULL,
    "y" double precision DEFAULT 0 NOT NULL,
    "width" double precision DEFAULT 180 NOT NULL,
    "height" double precision DEFAULT 80 NOT NULL,
    "z_index" integer DEFAULT 0 NOT NULL,
    "color" "text",
    "icon" "text",
    "node_type" "text" DEFAULT 'default'::"text" NOT NULL,
    "is_selected" boolean DEFAULT false NOT NULL,
    "is_collapsed" boolean DEFAULT false NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "block_id" "uuid",
    "is_root" boolean DEFAULT false NOT NULL,
    "label" "text" DEFAULT ''::"text" NOT NULL
);


ALTER TABLE "public"."mind_map_nodes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."mind_map_ports" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "node_id" "uuid" NOT NULL,
    "side" "text" NOT NULL,
    "direction" "text" DEFAULT 'both'::"text" NOT NULL,
    "position" double precision DEFAULT 0.5 NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "mind_map_ports_direction_check" CHECK (("direction" = ANY (ARRAY['input'::"text", 'output'::"text", 'both'::"text"]))),
    CONSTRAINT "mind_map_ports_side_check" CHECK (("side" = ANY (ARRAY['top'::"text", 'right'::"text", 'bottom'::"text", 'left'::"text"])))
);


ALTER TABLE "public"."mind_map_ports" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."note_blocks" (
    "block_id" "uuid" NOT NULL,
    "content" "text" DEFAULT ''::"text" NOT NULL,
    "format" "text" DEFAULT 'plain'::"text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."note_blocks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."photo_blocks" (
    "block_id" "uuid" NOT NULL,
    "storage_path" "text",
    "image_url" "text",
    "caption" "text",
    "alt_text" "text",
    "width" double precision,
    "height" double precision,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."photo_blocks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "full_name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."reminders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "remind_at" timestamp with time zone NOT NULL,
    "source_type" "text",
    "source_id" "text",
    "notify_in_app" boolean DEFAULT true NOT NULL,
    "notify_telegram" boolean DEFAULT false NOT NULL,
    "sent_in_app" boolean DEFAULT false NOT NULL,
    "sent_telegram" boolean DEFAULT false NOT NULL,
    "completed" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."reminders" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."routine_blocks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "routine_id" "uuid",
    "routine_day_id" "uuid",
    "block_type" "text",
    "title" "text",
    "position" integer DEFAULT 0 NOT NULL,
    "is_collapsed" boolean DEFAULT false NOT NULL,
    "is_hidden" boolean DEFAULT false NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "type" "text" DEFAULT 'note'::"text" NOT NULL,
    "content" "text" DEFAULT ''::"text" NOT NULL,
    "content_status" "text" DEFAULT 'idea'::"text" NOT NULL,
    "position_x" double precision,
    "position_y" double precision,
    "width" double precision,
    "height" double precision,
    "attachment_id" "uuid",
    CONSTRAINT "routine_blocks_type_check" CHECK (("type" = ANY (ARRAY['task'::"text", 'note'::"text", 'content'::"text", 'photo'::"text", 'mind_map'::"text", 'document'::"text"])))
);


ALTER TABLE "public"."routine_blocks" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."task_blocks" (
    "block_id" "uuid" NOT NULL,
    "description" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."task_blocks" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."routine_blocks_view" WITH ("security_invoker"='true') AS
 SELECT "b"."id",
    "b"."routine_id",
    "b"."routine_day_id",
    "b"."block_type",
    "b"."title",
    "b"."position",
    "b"."is_collapsed",
    "b"."is_hidden",
    "b"."metadata",
    "b"."created_at",
    "b"."updated_at",
    "n"."content" AS "note_content",
    "c"."content" AS "content_value",
    "c"."content_type",
    "p"."storage_path" AS "photo_storage_path",
    "p"."image_url" AS "photo_url",
    "p"."caption" AS "photo_caption",
    "t"."description" AS "task_description",
    "mb"."zoom" AS "mind_map_zoom",
    "mb"."offset_x" AS "mind_map_offset_x",
    "mb"."offset_y" AS "mind_map_offset_y"
   FROM ((((("public"."routine_blocks" "b"
     LEFT JOIN "public"."note_blocks" "n" ON (("n"."block_id" = "b"."id")))
     LEFT JOIN "public"."content_blocks" "c" ON (("c"."block_id" = "b"."id")))
     LEFT JOIN "public"."photo_blocks" "p" ON (("p"."block_id" = "b"."id")))
     LEFT JOIN "public"."task_blocks" "t" ON (("t"."block_id" = "b"."id")))
     LEFT JOIN "public"."mind_map_blocks" "mb" ON (("mb"."block_id" = "b"."id")));


ALTER VIEW "public"."routine_blocks_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."routine_comments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "day_id" "text" NOT NULL,
    "message" "text" NOT NULL,
    "position_x" double precision DEFAULT 0 NOT NULL,
    "position_y" double precision DEFAULT 0 NOT NULL,
    "author_name" "text" DEFAULT 'Você'::"text" NOT NULL,
    "resolved" boolean DEFAULT false NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "routine_comments_day_id_not_empty" CHECK (("length"(TRIM(BOTH FROM "day_id")) > 0)),
    CONSTRAINT "routine_comments_message_not_empty" CHECK (("length"(TRIM(BOTH FROM "message")) > 0))
);


ALTER TABLE "public"."routine_comments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."routine_days" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "routine_id" "uuid",
    "day_of_week" integer,
    "date" "date",
    "title" "text",
    "note" "text",
    "position" integer DEFAULT 0 NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid",
    "focus" "text" DEFAULT ''::"text" NOT NULL,
    CONSTRAINT "routine_days_day_of_week_check" CHECK ((("day_of_week" >= 1) AND ("day_of_week" <= 7)))
);


ALTER TABLE "public"."routine_days" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."routines" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "title" "text" DEFAULT 'Minha rotina'::"text" NOT NULL,
    "description" "text",
    "week_start" "date",
    "is_template" boolean DEFAULT false NOT NULL,
    "is_archived" boolean DEFAULT false NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."routines" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."study_data" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "day" "text" NOT NULL,
    "minutes" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "study_data_minutes_check" CHECK (("minutes" >= 0))
);


ALTER TABLE "public"."study_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."task_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "task_block_id" "uuid",
    "title" "text" DEFAULT ''::"text",
    "description" "text",
    "is_completed" boolean DEFAULT false NOT NULL,
    "position" integer DEFAULT 0 NOT NULL,
    "due_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "block_id" "uuid",
    "text" "text" DEFAULT ''::"text" NOT NULL,
    "completed" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."task_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."telegram_connections" (
    "user_id" "uuid" NOT NULL,
    "chat_id" "text" NOT NULL,
    "enabled" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "username" "text",
    "first_name" "text",
    "connected_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "telegram_connections_chat_id_not_blank" CHECK (("length"("btrim"("chat_id")) > 0)),
    CONSTRAINT "telegram_connections_username_not_blank" CHECK ((("username" IS NULL) OR ("length"("btrim"("username")) > 0)))
);


ALTER TABLE "public"."telegram_connections" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."telegram_link_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "token_hash" "text" NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "consumed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "telegram_link_requests_token_hash_not_blank" CHECK ((("token_hash" IS NULL) OR ("length"("btrim"("token_hash")) > 0)))
);


ALTER TABLE "public"."telegram_link_requests" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_activity_plans" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "activity" "text" NOT NULL,
    "weekdays" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "training_activity_plans_activity_check" CHECK (("activity" = ANY (ARRAY['chest'::"text", 'legs'::"text", 'arms'::"text", 'back'::"text", 'shoulders'::"text", 'core'::"text", 'running'::"text", 'walking'::"text"]))),
    CONSTRAINT "training_activity_plans_weekdays_check" CHECK (("weekdays" <@ ARRAY[1, 2, 3, 4, 5, 6, 7]))
);


ALTER TABLE "public"."training_activity_plans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_data" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "day" "text" NOT NULL,
    "training" "text" DEFAULT ''::"text" NOT NULL,
    "date" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."training_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."training_plans" (
    "user_id" "uuid" NOT NULL,
    "weekly_goal" integer DEFAULT 1 NOT NULL,
    "planned_weekdays" integer[] DEFAULT '{}'::integer[] NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "training_plans_weekly_goal_check" CHECK (("weekly_goal" > 0))
);


ALTER TABLE "public"."training_plans" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_devices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "device_id" "text" NOT NULL,
    "device_name" "text" NOT NULL,
    "platform" "text" NOT NULL,
    "app_version" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "revoked_at" timestamp with time zone,
    "session_id" "uuid" NOT NULL,
    "ended_at" timestamp with time zone,
    CONSTRAINT "user_devices_device_id_not_blank" CHECK (("length"(TRIM(BOTH FROM "device_id")) > 0)),
    CONSTRAINT "user_devices_device_name_not_blank" CHECK (("length"(TRIM(BOTH FROM "device_name")) > 0)),
    CONSTRAINT "user_devices_platform_not_blank" CHECK (("length"(TRIM(BOTH FROM "platform")) > 0))
);


ALTER TABLE "public"."user_devices" OWNER TO "postgres";


ALTER TABLE ONLY "public"."app_updates"
    ADD CONSTRAINT "app_updates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_updates_test"
    ADD CONSTRAINT "app_updates_test_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_updates"
    ADD CONSTRAINT "app_updates_version_key" UNIQUE ("version");



ALTER TABLE ONLY "public"."board_attachments"
    ADD CONSTRAINT "board_attachments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."brain_concepts"
    ADD CONSTRAINT "brain_concepts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."brain_device_key_envelopes"
    ADD CONSTRAINT "brain_device_key_envelopes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."brain_device_key_envelopes"
    ADD CONSTRAINT "brain_device_key_envelopes_user_id_vault_id_envelope_id_key" UNIQUE ("user_id", "vault_id", "envelope_id");



ALTER TABLE ONLY "public"."brain_devices"
    ADD CONSTRAINT "brain_devices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."brain_devices"
    ADD CONSTRAINT "brain_devices_user_id_vault_id_device_id_key" UNIQUE ("user_id", "vault_id", "device_id");



ALTER TABLE ONLY "public"."brain_notes"
    ADD CONSTRAINT "brain_notes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."brain_objects"
    ADD CONSTRAINT "brain_objects_pkey" PRIMARY KEY ("user_id", "vault_id", "object_id");



ALTER TABLE ONLY "public"."brain_reviews"
    ADD CONSTRAINT "brain_reviews_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."content_blocks"
    ADD CONSTRAINT "content_blocks_pkey" PRIMARY KEY ("block_id");



ALTER TABLE ONLY "public"."finance_contributions"
    ADD CONSTRAINT "finance_contributions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."finance_data"
    ADD CONSTRAINT "finance_data_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."finance_objectives"
    ADD CONSTRAINT "finance_objectives_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."journey_history"
    ADD CONSTRAINT "journey_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."journey_history"
    ADD CONSTRAINT "journey_history_user_date_unique" UNIQUE ("user_id", "date");



ALTER TABLE ONLY "public"."mind_map_blocks"
    ADD CONSTRAINT "mind_map_blocks_pkey" PRIMARY KEY ("block_id");



ALTER TABLE ONLY "public"."mind_map_connections"
    ADD CONSTRAINT "mind_map_connections_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mind_map_nodes"
    ADD CONSTRAINT "mind_map_nodes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."mind_map_ports"
    ADD CONSTRAINT "mind_map_ports_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."note_blocks"
    ADD CONSTRAINT "note_blocks_pkey" PRIMARY KEY ("block_id");



ALTER TABLE ONLY "public"."photo_blocks"
    ADD CONSTRAINT "photo_blocks_pkey" PRIMARY KEY ("block_id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."reminders"
    ADD CONSTRAINT "reminders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."routine_blocks"
    ADD CONSTRAINT "routine_blocks_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."routine_comments"
    ADD CONSTRAINT "routine_comments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."routine_days"
    ADD CONSTRAINT "routine_days_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."routine_days"
    ADD CONSTRAINT "routine_days_routine_id_day_of_week_key" UNIQUE ("routine_id", "day_of_week");



ALTER TABLE ONLY "public"."routines"
    ADD CONSTRAINT "routines_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."study_data"
    ADD CONSTRAINT "study_data_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."study_data"
    ADD CONSTRAINT "study_data_user_day_unique" UNIQUE ("user_id", "day");



ALTER TABLE ONLY "public"."task_blocks"
    ADD CONSTRAINT "task_blocks_pkey" PRIMARY KEY ("block_id");



ALTER TABLE ONLY "public"."task_items"
    ADD CONSTRAINT "task_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."telegram_connections"
    ADD CONSTRAINT "telegram_connections_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."telegram_link_requests"
    ADD CONSTRAINT "telegram_link_requests_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_activity_plans"
    ADD CONSTRAINT "training_activity_plans_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_activity_plans"
    ADD CONSTRAINT "training_activity_plans_user_activity_unique" UNIQUE ("user_id", "activity");



ALTER TABLE ONLY "public"."training_data"
    ADD CONSTRAINT "training_data_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."training_data"
    ADD CONSTRAINT "training_data_user_day_date_training_key" UNIQUE ("user_id", "day", "date", "training");



ALTER TABLE ONLY "public"."training_plans"
    ADD CONSTRAINT "training_plans_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_user_session_unique" UNIQUE ("user_id", "session_id");



CREATE INDEX "app_updates_active_idx" ON "public"."app_updates" USING "btree" ("active");



CREATE INDEX "app_updates_active_published_at_idx" ON "public"."app_updates" USING "btree" ("active", "published_at" DESC);



CREATE INDEX "app_updates_published_at_idx" ON "public"."app_updates" USING "btree" ("published_at" DESC);



CREATE INDEX "brain_device_envelope_claim_idx" ON "public"."brain_device_key_envelopes" USING "btree" ("user_id", "vault_id", "target_device_id", "consumed_at", "expires_at");



CREATE UNIQUE INDEX "brain_device_envelope_request_unique" ON "public"."brain_device_key_envelopes" USING "btree" ("user_id", "vault_id", "recovery_request_id") WHERE ("recovery_request_id" IS NOT NULL);



CREATE INDEX "brain_device_pending_expiry_idx" ON "public"."brain_devices" USING "btree" ("user_id", "vault_id", "status", "recovery_expires_at");



CREATE INDEX "brain_devices_user_vault_idx" ON "public"."brain_devices" USING "btree" ("user_id", "vault_id");



CREATE INDEX "brain_objects_user_vault_updated_idx" ON "public"."brain_objects" USING "btree" ("user_id", "vault_id", "updated_at");



CREATE INDEX "brain_reviews_archived_idx" ON "public"."brain_reviews" USING "btree" ("archived");



CREATE INDEX "brain_reviews_concept_id_idx" ON "public"."brain_reviews" USING "btree" ("concept_id");



CREATE INDEX "brain_reviews_next_review_at_idx" ON "public"."brain_reviews" USING "btree" ("next_review_at");



CREATE INDEX "brain_reviews_user_id_idx" ON "public"."brain_reviews" USING "btree" ("user_id");



CREATE INDEX "finance_contributions_user_date_idx" ON "public"."finance_contributions" USING "btree" ("user_id", "contribution_date");



CREATE INDEX "finance_contributions_user_id_idx" ON "public"."finance_contributions" USING "btree" ("user_id");



CREATE INDEX "idx_board_attachments_block_id" ON "public"."board_attachments" USING "btree" ("user_id", "board_id", "block_id");



CREATE INDEX "idx_board_attachments_board_id" ON "public"."board_attachments" USING "btree" ("user_id", "board_id");



CREATE INDEX "idx_board_attachments_remote_path" ON "public"."board_attachments" USING "btree" ("remote_path");



CREATE INDEX "idx_board_attachments_user_id" ON "public"."board_attachments" USING "btree" ("user_id");



CREATE INDEX "idx_brain_concepts_note" ON "public"."brain_concepts" USING "btree" ("note_id");



CREATE INDEX "idx_brain_concepts_updated" ON "public"."brain_concepts" USING "btree" ("user_id", "updated_at" DESC);



CREATE INDEX "idx_brain_concepts_user" ON "public"."brain_concepts" USING "btree" ("user_id");



CREATE INDEX "idx_brain_concepts_user_type" ON "public"."brain_concepts" USING "btree" ("user_id", "type");



CREATE INDEX "idx_brain_notes_topic" ON "public"."brain_notes" USING "btree" ("user_id", "topic");



CREATE INDEX "idx_brain_notes_user" ON "public"."brain_notes" USING "btree" ("user_id");



CREATE INDEX "idx_brain_notes_user_updated" ON "public"."brain_notes" USING "btree" ("user_id", "updated_at" DESC);



CREATE INDEX "idx_brain_reviews_concept" ON "public"."brain_reviews" USING "btree" ("concept_id");



CREATE INDEX "idx_brain_reviews_due" ON "public"."brain_reviews" USING "btree" ("user_id", "archived", "next_review_at");



CREATE INDEX "idx_brain_reviews_updated" ON "public"."brain_reviews" USING "btree" ("user_id", "updated_at" DESC);



CREATE INDEX "idx_brain_reviews_user" ON "public"."brain_reviews" USING "btree" ("user_id");



CREATE INDEX "idx_journey_history_user_date" ON "public"."journey_history" USING "btree" ("user_id", "date");



CREATE INDEX "idx_journey_history_user_id" ON "public"."journey_history" USING "btree" ("user_id");



CREATE INDEX "idx_mind_map_connections_block" ON "public"."mind_map_connections" USING "btree" ("mind_map_block_id");



CREATE INDEX "idx_mind_map_connections_source" ON "public"."mind_map_connections" USING "btree" ("source_node_id");



CREATE INDEX "idx_mind_map_connections_target" ON "public"."mind_map_connections" USING "btree" ("target_node_id");



CREATE INDEX "idx_mind_map_nodes_block" ON "public"."mind_map_nodes" USING "btree" ("mind_map_block_id");



CREATE INDEX "idx_mind_map_nodes_block_id_app" ON "public"."mind_map_nodes" USING "btree" ("block_id");



CREATE INDEX "idx_mind_map_nodes_mind_map_block_id" ON "public"."mind_map_nodes" USING "btree" ("mind_map_block_id");



CREATE INDEX "idx_mind_map_ports_node" ON "public"."mind_map_ports" USING "btree" ("node_id");



CREATE INDEX "idx_routine_blocks_attachment_id" ON "public"."routine_blocks" USING "btree" ("attachment_id");



CREATE INDEX "idx_routine_blocks_day" ON "public"."routine_blocks" USING "btree" ("routine_day_id");



CREATE INDEX "idx_routine_blocks_position" ON "public"."routine_blocks" USING "btree" ("routine_day_id", "position");



CREATE INDEX "idx_routine_blocks_routine" ON "public"."routine_blocks" USING "btree" ("routine_id");



CREATE INDEX "idx_routine_blocks_type" ON "public"."routine_blocks" USING "btree" ("block_type");



CREATE INDEX "idx_routine_blocks_type_app" ON "public"."routine_blocks" USING "btree" ("type");



CREATE INDEX "idx_routine_comments_created_at" ON "public"."routine_comments" USING "btree" ("created_at");



CREATE INDEX "idx_routine_comments_user_day" ON "public"."routine_comments" USING "btree" ("user_id", "day_id");



CREATE INDEX "idx_routine_comments_user_day_resolved" ON "public"."routine_comments" USING "btree" ("user_id", "day_id", "resolved");



CREATE INDEX "idx_routine_comments_user_id" ON "public"."routine_comments" USING "btree" ("user_id");



CREATE INDEX "idx_routine_days_date" ON "public"."routine_days" USING "btree" ("date");



CREATE INDEX "idx_routine_days_routine" ON "public"."routine_days" USING "btree" ("routine_id");



CREATE INDEX "idx_routine_days_user_date" ON "public"."routine_days" USING "btree" ("user_id", "date");



CREATE INDEX "idx_routine_days_user_id" ON "public"."routine_days" USING "btree" ("user_id");



CREATE INDEX "idx_routines_user_id" ON "public"."routines" USING "btree" ("user_id");



CREATE INDEX "idx_routines_week_start" ON "public"."routines" USING "btree" ("user_id", "week_start");



CREATE INDEX "idx_study_data_user_day" ON "public"."study_data" USING "btree" ("user_id", "day");



CREATE INDEX "idx_study_data_user_id" ON "public"."study_data" USING "btree" ("user_id");



CREATE INDEX "idx_task_items_block" ON "public"."task_items" USING "btree" ("task_block_id");



CREATE INDEX "idx_task_items_block_id_app" ON "public"."task_items" USING "btree" ("block_id");



CREATE INDEX "idx_task_items_block_position_app" ON "public"."task_items" USING "btree" ("block_id", "position");



CREATE INDEX "idx_task_items_position" ON "public"."task_items" USING "btree" ("task_block_id", "position");



CREATE INDEX "idx_training_data_date" ON "public"."training_data" USING "btree" ("user_id", "date");



CREATE INDEX "idx_training_data_user_id" ON "public"."training_data" USING "btree" ("user_id");



CREATE INDEX "idx_training_plans_user_id" ON "public"."training_plans" USING "btree" ("user_id");



CREATE INDEX "mind_map_nodes_block_root_idx" ON "public"."mind_map_nodes" USING "btree" ("mind_map_block_id", "is_root");



CREATE INDEX "mind_map_nodes_is_root_idx" ON "public"."mind_map_nodes" USING "btree" ("is_root");



CREATE UNIQUE INDEX "mind_map_nodes_one_root_per_map_idx" ON "public"."mind_map_nodes" USING "btree" ("mind_map_block_id") WHERE ("is_root" = true);



CREATE INDEX "telegram_connections_chat_id_idx" ON "public"."telegram_connections" USING "btree" ("chat_id");



CREATE UNIQUE INDEX "telegram_connections_chat_id_uidx" ON "public"."telegram_connections" USING "btree" ("chat_id");



CREATE UNIQUE INDEX "telegram_connections_user_id_uidx" ON "public"."telegram_connections" USING "btree" ("user_id");



CREATE INDEX "telegram_link_requests_expires_at_idx" ON "public"."telegram_link_requests" USING "btree" ("expires_at");



CREATE INDEX "telegram_link_requests_pending_idx" ON "public"."telegram_link_requests" USING "btree" ("user_id", "expires_at") WHERE ("consumed_at" IS NULL);



CREATE UNIQUE INDEX "telegram_link_requests_token_hash_uidx" ON "public"."telegram_link_requests" USING "btree" ("token_hash") WHERE ("token_hash" IS NOT NULL);



CREATE INDEX "telegram_link_requests_user_id_idx" ON "public"."telegram_link_requests" USING "btree" ("user_id");



CREATE INDEX "training_activity_plans_activity_idx" ON "public"."training_activity_plans" USING "btree" ("activity");



CREATE INDEX "training_activity_plans_user_id_idx" ON "public"."training_activity_plans" USING "btree" ("user_id");



CREATE UNIQUE INDEX "uq_brain_reviews_user_concept" ON "public"."brain_reviews" USING "btree" ("user_id", "concept_id");



CREATE UNIQUE INDEX "uq_routine_days_user_date" ON "public"."routine_days" USING "btree" ("user_id", "date") WHERE (("user_id" IS NOT NULL) AND ("date" IS NOT NULL));



CREATE INDEX "user_devices_active_idx" ON "public"."user_devices" USING "btree" ("user_id", "last_seen_at" DESC) WHERE (("revoked_at" IS NULL) AND ("ended_at" IS NULL));



CREATE INDEX "user_devices_last_seen_idx" ON "public"."user_devices" USING "btree" ("last_seen_at" DESC);



CREATE INDEX "user_devices_session_id_idx" ON "public"."user_devices" USING "btree" ("session_id");



CREATE INDEX "user_devices_user_id_idx" ON "public"."user_devices" USING "btree" ("user_id");



CREATE INDEX "user_devices_user_last_seen_idx" ON "public"."user_devices" USING "btree" ("user_id", "last_seen_at" DESC);



CREATE OR REPLACE TRIGGER "board_attachments_set_updated_at" BEFORE UPDATE ON "public"."board_attachments" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_app_updates_updated_at" BEFORE UPDATE ON "public"."app_updates" FOR EACH ROW EXECUTE FUNCTION "public"."set_app_updates_updated_at"();



CREATE OR REPLACE TRIGGER "set_brain_concepts_updated_at" BEFORE UPDATE ON "public"."brain_concepts" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_brain_notes_updated_at" BEFORE UPDATE ON "public"."brain_notes" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_brain_reviews_updated_at" BEFORE UPDATE ON "public"."brain_reviews" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "telegram_connections_set_updated_at" BEFORE UPDATE ON "public"."telegram_connections" FOR EACH ROW EXECUTE FUNCTION "public"."set_telegram_connection_updated_at"();



CREATE OR REPLACE TRIGGER "trg_content_blocks_updated_at" BEFORE UPDATE ON "public"."content_blocks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_mind_map_blocks_updated_at" BEFORE UPDATE ON "public"."mind_map_blocks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_mind_map_connections_updated_at" BEFORE UPDATE ON "public"."mind_map_connections" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_mind_map_nodes_updated_at" BEFORE UPDATE ON "public"."mind_map_nodes" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_note_blocks_updated_at" BEFORE UPDATE ON "public"."note_blocks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_photo_blocks_updated_at" BEFORE UPDATE ON "public"."photo_blocks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_routine_blocks_updated_at" BEFORE UPDATE ON "public"."routine_blocks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_routine_days_updated_at" BEFORE UPDATE ON "public"."routine_days" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_routines_updated_at" BEFORE UPDATE ON "public"."routines" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_task_blocks_updated_at" BEFORE UPDATE ON "public"."task_blocks" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_task_completed_at" BEFORE UPDATE OF "is_completed" ON "public"."task_items" FOR EACH ROW EXECUTE FUNCTION "public"."sync_task_completed_at"();



CREATE OR REPLACE TRIGGER "trg_task_items_updated_at" BEFORE UPDATE ON "public"."task_items" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_routine_comments_updated_at" BEFORE UPDATE ON "public"."routine_comments" FOR EACH ROW EXECUTE FUNCTION "public"."update_routine_comments_updated_at"();



CREATE OR REPLACE TRIGGER "validate_brain_concept_owner_trigger" BEFORE INSERT OR UPDATE ON "public"."brain_concepts" FOR EACH ROW EXECUTE FUNCTION "public"."validate_brain_concept_owner"();



CREATE OR REPLACE TRIGGER "validate_brain_review_owner_trigger" BEFORE INSERT OR UPDATE ON "public"."brain_reviews" FOR EACH ROW EXECUTE FUNCTION "public"."validate_brain_review_owner"();



ALTER TABLE ONLY "public"."board_attachments"
    ADD CONSTRAINT "board_attachments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."brain_concepts"
    ADD CONSTRAINT "brain_concepts_note_id_fkey" FOREIGN KEY ("note_id") REFERENCES "public"."brain_notes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."brain_concepts"
    ADD CONSTRAINT "brain_concepts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."brain_device_key_envelopes"
    ADD CONSTRAINT "brain_device_key_envelopes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."brain_devices"
    ADD CONSTRAINT "brain_devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."brain_notes"
    ADD CONSTRAINT "brain_notes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."brain_objects"
    ADD CONSTRAINT "brain_objects_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."brain_reviews"
    ADD CONSTRAINT "brain_reviews_concept_id_fkey" FOREIGN KEY ("concept_id") REFERENCES "public"."brain_concepts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."brain_reviews"
    ADD CONSTRAINT "brain_reviews_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."content_blocks"
    ADD CONSTRAINT "content_blocks_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "public"."routine_blocks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."finance_contributions"
    ADD CONSTRAINT "finance_contributions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."finance_data"
    ADD CONSTRAINT "finance_data_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."finance_objectives"
    ADD CONSTRAINT "finance_objectives_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."journey_history"
    ADD CONSTRAINT "journey_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mind_map_blocks"
    ADD CONSTRAINT "mind_map_blocks_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "public"."routine_blocks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mind_map_connections"
    ADD CONSTRAINT "mind_map_connections_mind_map_block_id_fkey" FOREIGN KEY ("mind_map_block_id") REFERENCES "public"."mind_map_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mind_map_connections"
    ADD CONSTRAINT "mind_map_connections_source_node_id_fkey" FOREIGN KEY ("source_node_id") REFERENCES "public"."mind_map_nodes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mind_map_connections"
    ADD CONSTRAINT "mind_map_connections_source_port_id_fkey" FOREIGN KEY ("source_port_id") REFERENCES "public"."mind_map_ports"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."mind_map_connections"
    ADD CONSTRAINT "mind_map_connections_target_node_id_fkey" FOREIGN KEY ("target_node_id") REFERENCES "public"."mind_map_nodes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mind_map_connections"
    ADD CONSTRAINT "mind_map_connections_target_port_id_fkey" FOREIGN KEY ("target_port_id") REFERENCES "public"."mind_map_ports"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."mind_map_nodes"
    ADD CONSTRAINT "mind_map_nodes_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "public"."routine_blocks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mind_map_nodes"
    ADD CONSTRAINT "mind_map_nodes_mind_map_block_id_fkey" FOREIGN KEY ("mind_map_block_id") REFERENCES "public"."routine_blocks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."mind_map_ports"
    ADD CONSTRAINT "mind_map_ports_node_id_fkey" FOREIGN KEY ("node_id") REFERENCES "public"."mind_map_nodes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."note_blocks"
    ADD CONSTRAINT "note_blocks_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "public"."routine_blocks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."photo_blocks"
    ADD CONSTRAINT "photo_blocks_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "public"."routine_blocks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."reminders"
    ADD CONSTRAINT "reminders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."routine_blocks"
    ADD CONSTRAINT "routine_blocks_attachment_id_fkey" FOREIGN KEY ("attachment_id") REFERENCES "public"."board_attachments"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."routine_blocks"
    ADD CONSTRAINT "routine_blocks_routine_day_id_fkey" FOREIGN KEY ("routine_day_id") REFERENCES "public"."routine_days"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."routine_blocks"
    ADD CONSTRAINT "routine_blocks_routine_id_fkey" FOREIGN KEY ("routine_id") REFERENCES "public"."routines"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."routine_comments"
    ADD CONSTRAINT "routine_comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."routine_days"
    ADD CONSTRAINT "routine_days_routine_id_fkey" FOREIGN KEY ("routine_id") REFERENCES "public"."routines"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."routine_days"
    ADD CONSTRAINT "routine_days_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."routines"
    ADD CONSTRAINT "routines_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."study_data"
    ADD CONSTRAINT "study_data_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_blocks"
    ADD CONSTRAINT "task_blocks_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "public"."routine_blocks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_items"
    ADD CONSTRAINT "task_items_block_id_fkey" FOREIGN KEY ("block_id") REFERENCES "public"."routine_blocks"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."task_items"
    ADD CONSTRAINT "task_items_task_block_id_fkey" FOREIGN KEY ("task_block_id") REFERENCES "public"."task_blocks"("block_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."telegram_connections"
    ADD CONSTRAINT "telegram_connections_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."telegram_link_requests"
    ADD CONSTRAINT "telegram_link_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_activity_plans"
    ADD CONSTRAINT "training_activity_plans_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_data"
    ADD CONSTRAINT "training_data_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."training_plans"
    ADD CONSTRAINT "training_plans_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_devices"
    ADD CONSTRAINT "user_devices_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Authenticated users can read app updates" ON "public"."app_updates" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Test account can read app updates" ON "public"."app_updates_test" FOR SELECT TO "authenticated" USING ((( SELECT "auth"."uid"() AS "uid") = '980210a5-e6a0-4abe-a3e6-bd14f4d14c99'::"uuid"));



CREATE POLICY "Users can create own journey history" ON "public"."journey_history" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can create own reminders" ON "public"."reminders" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can create own study data" ON "public"."study_data" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can create own training activity plans" ON "public"."training_activity_plans" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can create own training data" ON "public"."training_data" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can create own training plan" ON "public"."training_plans" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own journey history" ON "public"."journey_history" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own reminders" ON "public"."reminders" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own study data" ON "public"."study_data" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own training activity plans" ON "public"."training_activity_plans" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own training data" ON "public"."training_data" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can delete own training plan" ON "public"."training_plans" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can insert own profile" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can read own journey history" ON "public"."journey_history" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own reminders" ON "public"."reminders" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own study data" ON "public"."study_data" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own training activity plans" ON "public"."training_activity_plans" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own training data" ON "public"."training_data" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can read own training plan" ON "public"."training_plans" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own journey history" ON "public"."journey_history" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own profile" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can update own reminders" ON "public"."reminders" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own study data" ON "public"."study_data" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own training activity plans" ON "public"."training_activity_plans" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own training data" ON "public"."training_data" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own training plan" ON "public"."training_plans" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view own profile" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



ALTER TABLE "public"."app_updates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."app_updates_test" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."board_attachments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "board_attachments_delete_own" ON "public"."board_attachments" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "board_attachments_insert_own" ON "public"."board_attachments" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "board_attachments_select_own" ON "public"."board_attachments" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "board_attachments_update_own" ON "public"."board_attachments" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."brain_concepts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "brain_concepts_delete_own" ON "public"."brain_concepts" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_concepts_insert_own" ON "public"."brain_concepts" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_concepts_select_own" ON "public"."brain_concepts" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_concepts_update_own" ON "public"."brain_concepts" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."brain_device_key_envelopes" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."brain_devices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."brain_notes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "brain_notes_delete_own" ON "public"."brain_notes" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_notes_insert_own" ON "public"."brain_notes" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_notes_select_own" ON "public"."brain_notes" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_notes_update_own" ON "public"."brain_notes" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."brain_objects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "brain_objects_insert_own" ON "public"."brain_objects" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_objects_select_own" ON "public"."brain_objects" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_objects_update_own" ON "public"."brain_objects" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."brain_reviews" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "brain_reviews_delete_own" ON "public"."brain_reviews" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_reviews_insert_own" ON "public"."brain_reviews" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_reviews_select_own" ON "public"."brain_reviews" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "brain_reviews_update_own" ON "public"."brain_reviews" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."content_blocks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."finance_contributions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "finance_contributions_delete_own" ON "public"."finance_contributions" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "finance_contributions_insert_own" ON "public"."finance_contributions" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "finance_contributions_select_own" ON "public"."finance_contributions" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "finance_contributions_update_own" ON "public"."finance_contributions" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."finance_data" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "finance_data_delete_own" ON "public"."finance_data" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "finance_data_insert_own" ON "public"."finance_data" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "finance_data_select_own" ON "public"."finance_data" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "finance_data_update_own" ON "public"."finance_data" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."finance_objectives" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "finance_objectives_delete_own" ON "public"."finance_objectives" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "finance_objectives_insert_own" ON "public"."finance_objectives" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "finance_objectives_select_own" ON "public"."finance_objectives" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "finance_objectives_update_own" ON "public"."finance_objectives" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."journey_history" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mind_map_blocks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mind_map_connections" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."mind_map_nodes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "mind_map_nodes_delete_own" ON "public"."mind_map_nodes" FOR DELETE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."routine_blocks" "rb"
     JOIN "public"."routine_days" "rd" ON (("rd"."id" = "rb"."routine_day_id")))
  WHERE (("rb"."id" = "mind_map_nodes"."mind_map_block_id") AND ("rd"."user_id" = "auth"."uid"())))));



CREATE POLICY "mind_map_nodes_insert_own" ON "public"."mind_map_nodes" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."routine_blocks" "rb"
     JOIN "public"."routine_days" "rd" ON (("rd"."id" = "rb"."routine_day_id")))
  WHERE (("rb"."id" = "mind_map_nodes"."mind_map_block_id") AND ("rd"."user_id" = "auth"."uid"())))));



CREATE POLICY "mind_map_nodes_select_own" ON "public"."mind_map_nodes" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."routine_blocks" "rb"
     JOIN "public"."routine_days" "rd" ON (("rd"."id" = "rb"."routine_day_id")))
  WHERE (("rb"."id" = "mind_map_nodes"."mind_map_block_id") AND ("rd"."user_id" = "auth"."uid"())))));



CREATE POLICY "mind_map_nodes_update_own" ON "public"."mind_map_nodes" FOR UPDATE TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."routine_blocks" "rb"
     JOIN "public"."routine_days" "rd" ON (("rd"."id" = "rb"."routine_day_id")))
  WHERE (("rb"."id" = "mind_map_nodes"."mind_map_block_id") AND ("rd"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."routine_blocks" "rb"
     JOIN "public"."routine_days" "rd" ON (("rd"."id" = "rb"."routine_day_id")))
  WHERE (("rb"."id" = "mind_map_nodes"."mind_map_block_id") AND ("rd"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."mind_map_ports" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."note_blocks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."photo_blocks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."reminders" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."routine_blocks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "routine_blocks_app_policy" ON "public"."routine_blocks" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."routine_days" "d"
  WHERE (("d"."id" = "routine_blocks"."routine_day_id") AND ("d"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."routine_days" "d"
  WHERE (("d"."id" = "routine_blocks"."routine_day_id") AND ("d"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."routine_comments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "routine_comments_delete_own" ON "public"."routine_comments" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "routine_comments_insert_own" ON "public"."routine_comments" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "routine_comments_select_own" ON "public"."routine_comments" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "routine_comments_update_own" ON "public"."routine_comments" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."routine_days" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "routine_days_delete" ON "public"."routine_days" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "routine_days_insert" ON "public"."routine_days" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "routine_days_select" ON "public"."routine_days" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "routine_days_update" ON "public"."routine_days" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."routines" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."study_data" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."task_blocks" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."task_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "task_items_app_policy" ON "public"."task_items" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."routine_blocks" "b"
     JOIN "public"."routine_days" "d" ON (("d"."id" = "b"."routine_day_id")))
  WHERE (("b"."id" = "task_items"."block_id") AND ("d"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."routine_blocks" "b"
     JOIN "public"."routine_days" "d" ON (("d"."id" = "b"."routine_day_id")))
  WHERE (("b"."id" = "task_items"."block_id") AND ("d"."user_id" = "auth"."uid"())))));



ALTER TABLE "public"."telegram_connections" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "telegram_connections_select_own" ON "public"."telegram_connections" FOR SELECT TO "authenticated" USING (("user_id" = ( SELECT "auth"."uid"() AS "uid")));



ALTER TABLE "public"."telegram_link_requests" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_activity_plans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_data" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."training_plans" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."user_devices" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_devices_select_own" ON "public"."user_devices" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "users can delete own telegram connection" ON "public"."telegram_connections" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "users can insert own telegram connection" ON "public"."telegram_connections" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "users can read own telegram connection" ON "public"."telegram_connections" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "users can update own telegram connection" ON "public"."telegram_connections" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "users_delete_own_routines" ON "public"."routines" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "users_insert_own_routines" ON "public"."routines" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "users_manage_own_content_blocks" ON "public"."content_blocks" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "content_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "content_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id")))));



CREATE POLICY "users_manage_own_mind_map_blocks" ON "public"."mind_map_blocks" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "mind_map_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "mind_map_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id")))));



CREATE POLICY "users_manage_own_mind_map_connections" ON "public"."mind_map_connections" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM ("public"."mind_map_blocks" "mb"
     JOIN "public"."routine_blocks" "b" ON (("b"."id" = "mb"."block_id")))
  WHERE (("mb"."block_id" = "mind_map_connections"."mind_map_block_id") AND "public"."is_routine_owner"("b"."routine_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("public"."mind_map_blocks" "mb"
     JOIN "public"."routine_blocks" "b" ON (("b"."id" = "mb"."block_id")))
  WHERE (("mb"."block_id" = "mind_map_connections"."mind_map_block_id") AND "public"."is_routine_owner"("b"."routine_id")))));



CREATE POLICY "users_manage_own_mind_map_ports" ON "public"."mind_map_ports" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM (("public"."mind_map_nodes" "n"
     JOIN "public"."mind_map_blocks" "mb" ON (("mb"."block_id" = "n"."mind_map_block_id")))
     JOIN "public"."routine_blocks" "b" ON (("b"."id" = "mb"."block_id")))
  WHERE (("n"."id" = "mind_map_ports"."node_id") AND "public"."is_routine_owner"("b"."routine_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (("public"."mind_map_nodes" "n"
     JOIN "public"."mind_map_blocks" "mb" ON (("mb"."block_id" = "n"."mind_map_block_id")))
     JOIN "public"."routine_blocks" "b" ON (("b"."id" = "mb"."block_id")))
  WHERE (("n"."id" = "mind_map_ports"."node_id") AND "public"."is_routine_owner"("b"."routine_id")))));



CREATE POLICY "users_manage_own_note_blocks" ON "public"."note_blocks" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "note_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "note_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id")))));



CREATE POLICY "users_manage_own_photo_blocks" ON "public"."photo_blocks" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "photo_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "photo_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id")))));



CREATE POLICY "users_manage_own_task_blocks" ON "public"."task_blocks" TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "task_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."routine_blocks" "b"
  WHERE (("b"."id" = "task_blocks"."block_id") AND "public"."is_routine_owner"("b"."routine_id")))));



CREATE POLICY "users_select_own_routines" ON "public"."routines" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "users_update_own_routines" ON "public"."routines" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";






ALTER PUBLICATION "supabase_realtime" ADD TABLE ONLY "public"."app_updates";









GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";











































































































































































REVOKE ALL ON FUNCTION "public"."_brain_device_authorized_internal"("p_user_id" "uuid", "p_vault_id" "text", "p_device_id" "text", "p_auth_secret" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."_brain_device_authorized_internal"("p_user_id" "uuid", "p_vault_id" "text", "p_device_id" "text", "p_auth_secret" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."approve_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text", "p_envelope" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."approve_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text", "p_envelope" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."approve_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text", "p_envelope" "jsonb") TO "service_role";



REVOKE ALL ON FUNCTION "public"."brain_device_is_authorized"("p_vault_id" "text", "p_device_id" "text", "p_auth_secret" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."brain_device_is_authorized"("p_vault_id" "text", "p_device_id" "text", "p_auth_secret" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."brain_device_is_authorized"("p_vault_id" "text", "p_device_id" "text", "p_auth_secret" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."claim_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."claim_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."consume_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text", "p_envelope_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."consume_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text", "p_envelope_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."disconnect_current_user_device"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."disconnect_current_user_device"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."disconnect_current_user_device"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."get_brain_device"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text", "p_target_device_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_brain_device"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text", "p_target_device_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_brain_device"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text", "p_target_device_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."is_routine_owner"("p_routine_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_routine_owner"("p_routine_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_routine_owner"("p_routine_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."list_brain_devices"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_brain_devices"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."list_brain_devices"("p_vault_id" "text", "p_requester_device_id" "text", "p_requester_secret" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."load_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."load_brain_device_envelope"("p_vault_id" "text", "p_target_device_id" "text", "p_target_secret" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."register_brain_device"("p_device_id" "text", "p_vault_id" "text", "p_device_name" "text", "p_public_key_b64" "text", "p_key_fingerprint" "text", "p_auth_secret" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."register_brain_device"("p_device_id" "text", "p_vault_id" "text", "p_device_name" "text", "p_public_key_b64" "text", "p_key_fingerprint" "text", "p_auth_secret" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."register_brain_device"("p_device_id" "text", "p_vault_id" "text", "p_device_name" "text", "p_public_key_b64" "text", "p_key_fingerprint" "text", "p_auth_secret" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."register_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."register_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."register_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."revoke_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."revoke_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."revoke_brain_device"("p_vault_id" "text", "p_approver_device_id" "text", "p_approver_secret" "text", "p_target_device_id" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."revoke_user_device"("p_session_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."revoke_user_device"("p_session_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."revoke_user_device"("p_session_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."rls_auto_enable"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_app_updates_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_app_updates_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_telegram_connection_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_telegram_connection_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."set_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."sync_task_completed_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."sync_task_completed_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."touch_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."touch_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."touch_user_device"("p_device_id" "text", "p_device_name" "text", "p_platform" "text", "p_app_version" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."update_routine_comments_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_routine_comments_updated_at"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."upsert_brain_object_e2ee"("p_vault_id" "text", "p_object_id" "text", "p_object_version" integer, "p_crypto_version" integer, "p_key_version" integer, "p_is_deleted" boolean, "p_encrypted_object" "jsonb", "p_created_at" timestamp with time zone, "p_updated_at" timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."upsert_brain_object_e2ee"("p_vault_id" "text", "p_object_id" "text", "p_object_version" integer, "p_crypto_version" integer, "p_key_version" integer, "p_is_deleted" boolean, "p_encrypted_object" "jsonb", "p_created_at" timestamp with time zone, "p_updated_at" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_brain_object_e2ee"("p_vault_id" "text", "p_object_id" "text", "p_object_version" integer, "p_crypto_version" integer, "p_key_version" integer, "p_is_deleted" boolean, "p_encrypted_object" "jsonb", "p_created_at" timestamp with time zone, "p_updated_at" timestamp with time zone) TO "service_role";



REVOKE ALL ON FUNCTION "public"."validate_brain_concept_owner"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validate_brain_concept_owner"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."validate_brain_review_owner"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."validate_brain_review_owner"() TO "service_role";
























GRANT SELECT,MAINTAIN ON TABLE "public"."app_updates" TO "authenticated";
GRANT ALL ON TABLE "public"."app_updates" TO "service_role";



GRANT ALL ON TABLE "public"."app_updates_test" TO "service_role";
GRANT SELECT ON TABLE "public"."app_updates_test" TO "authenticated";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."board_attachments" TO "authenticated";
GRANT ALL ON TABLE "public"."board_attachments" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."brain_concepts" TO "authenticated";
GRANT ALL ON TABLE "public"."brain_concepts" TO "service_role";



GRANT ALL ON TABLE "public"."brain_device_key_envelopes" TO "service_role";



GRANT ALL ON TABLE "public"."brain_devices" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."brain_notes" TO "authenticated";
GRANT ALL ON TABLE "public"."brain_notes" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."brain_objects" TO "authenticated";
GRANT ALL ON TABLE "public"."brain_objects" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."brain_reviews" TO "authenticated";
GRANT ALL ON TABLE "public"."brain_reviews" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."content_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."content_blocks" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."finance_contributions" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_contributions" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."finance_data" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_data" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."finance_objectives" TO "authenticated";
GRANT ALL ON TABLE "public"."finance_objectives" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."journey_history" TO "authenticated";
GRANT ALL ON TABLE "public"."journey_history" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."mind_map_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."mind_map_blocks" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."mind_map_connections" TO "authenticated";
GRANT ALL ON TABLE "public"."mind_map_connections" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."mind_map_nodes" TO "authenticated";
GRANT ALL ON TABLE "public"."mind_map_nodes" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."mind_map_ports" TO "authenticated";
GRANT ALL ON TABLE "public"."mind_map_ports" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."note_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."note_blocks" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."photo_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."photo_blocks" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."reminders" TO "authenticated";
GRANT ALL ON TABLE "public"."reminders" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."routine_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."routine_blocks" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."task_blocks" TO "authenticated";
GRANT ALL ON TABLE "public"."task_blocks" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."routine_blocks_view" TO "authenticated";
GRANT ALL ON TABLE "public"."routine_blocks_view" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."routine_comments" TO "authenticated";
GRANT ALL ON TABLE "public"."routine_comments" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."routine_days" TO "authenticated";
GRANT ALL ON TABLE "public"."routine_days" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."routines" TO "authenticated";
GRANT ALL ON TABLE "public"."routines" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."study_data" TO "authenticated";
GRANT ALL ON TABLE "public"."study_data" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."task_items" TO "authenticated";
GRANT ALL ON TABLE "public"."task_items" TO "service_role";



GRANT SELECT,MAINTAIN ON TABLE "public"."telegram_connections" TO "authenticated";
GRANT ALL ON TABLE "public"."telegram_connections" TO "service_role";



GRANT ALL ON TABLE "public"."telegram_link_requests" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."training_activity_plans" TO "authenticated";
GRANT ALL ON TABLE "public"."training_activity_plans" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."training_data" TO "authenticated";
GRANT ALL ON TABLE "public"."training_data" TO "service_role";



GRANT SELECT,INSERT,DELETE,MAINTAIN,UPDATE ON TABLE "public"."training_plans" TO "authenticated";
GRANT ALL ON TABLE "public"."training_plans" TO "service_role";



GRANT ALL ON TABLE "public"."user_devices" TO "service_role";
GRANT SELECT ON TABLE "public"."user_devices" TO "authenticated";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";



































