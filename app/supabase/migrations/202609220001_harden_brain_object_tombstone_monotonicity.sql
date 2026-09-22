-- EVRYLUX Brain — Production delete lifecycle / Phase 2
--
-- Harden monotonic E2EE upsert semantics:
-- - newer versions may replace older versions;
-- - equal versions remain idempotent;
-- - once a row is a tombstone, no ACTIVE payload (equal or newer) may revive it;
-- - newer tombstones may still advance the version monotonically.
--
-- This migration does not delete any brain_objects row and does not expose
-- logical E2EE content.

create or replace function public.upsert_brain_object_e2ee(
  p_vault_id text,
  p_object_id text,
  p_object_version integer,
  p_crypto_version integer,
  p_key_version integer,
  p_is_deleted boolean,
  p_encrypted_object jsonb,
  p_created_at timestamptz,
  p_updated_at timestamptz
) returns void
language plpgsql
set search_path to 'public'
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_vault_id is null or btrim(p_vault_id) = '' then
    raise exception 'invalid_vault_id';
  end if;

  if p_object_id is null or btrim(p_object_id) = '' then
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
  on conflict (user_id, vault_id, object_id)
  do update set
    object_version = excluded.object_version,
    crypto_version = excluded.crypto_version,
    key_version = excluded.key_version,
    is_deleted = excluded.is_deleted,
    encrypted_object = excluded.encrypted_object,
    created_at = least(public.brain_objects.created_at, excluded.created_at),
    updated_at = excluded.updated_at,
    server_updated_at = now()
  where
    public.brain_objects.object_version <= excluded.object_version
    and (
      public.brain_objects.is_deleted = false
      or excluded.is_deleted = true
    );
end;
$$;

revoke all on function public.upsert_brain_object_e2ee(
  text, text, integer, integer, integer, boolean, jsonb, timestamptz, timestamptz
) from public;

grant execute on function public.upsert_brain_object_e2ee(
  text, text, integer, integer, integer, boolean, jsonb, timestamptz, timestamptz
) to authenticated;

grant execute on function public.upsert_brain_object_e2ee(
  text, text, integer, integer, integer, boolean, jsonb, timestamptz, timestamptz
) to service_role;

-- Capability/confirmation RPC used by local compaction. Because this function
-- is introduced by the same migration that hardens tombstone monotonicity,
-- clients fail closed if the Phase 2 database migration was not applied.
create or replace function public.confirm_brain_tombstone_for_local_compaction(
  p_vault_id text,
  p_object_id text,
  p_min_object_version integer
) returns boolean
language plpgsql
stable
set search_path to 'public'
as $$
declare
  v_user_id uuid;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_vault_id is null or btrim(p_vault_id) = '' then
    raise exception 'invalid_vault_id';
  end if;

  if p_object_id is null or btrim(p_object_id) = '' then
    raise exception 'invalid_object_id';
  end if;

  if p_min_object_version <= 0 then
    raise exception 'invalid_version';
  end if;

  return exists (
    select 1
    from public.brain_objects bo
    where bo.user_id = v_user_id
      and bo.vault_id = p_vault_id
      and bo.object_id = p_object_id
      and bo.is_deleted = true
      and bo.object_version >= p_min_object_version
  );
end;
$$;

revoke all on function public.confirm_brain_tombstone_for_local_compaction(
  text, text, integer
) from public;

grant execute on function public.confirm_brain_tombstone_for_local_compaction(
  text, text, integer
) to authenticated;

grant execute on function public.confirm_brain_tombstone_for_local_compaction(
  text, text, integer
) to service_role;
