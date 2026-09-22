-- EVRYLUX Brain — Production delete lifecycle / Phase 3
--
-- Remote garbage collection with durable deletion floors and per-device
-- acknowledgements. No logical Brain content is stored in these tables.
--
-- Safety model:
--   1. brain_objects keeps the full encrypted tombstone during retention;
--   2. every currently-authorized Brain device must acknowledge that tombstone;
--   3. GC transaction persists a deletion floor BEFORE deleting brain_objects;
--   4. stale ACTIVE writes for a deleted objectId are ignored forever;
--   5. revoked devices do not block GC; authorized offline devices do.

create table if not exists public.brain_deletion_floors (
  user_id uuid not null references auth.users(id) on delete cascade,
  vault_id text not null,
  object_id text not null,
  object_version integer not null,
  deleted_at timestamptz not null,
  compacted_at timestamptz not null default now(),
  source_server_updated_at timestamptz,
  constraint brain_deletion_floors_pkey
    primary key (user_id, vault_id, object_id),
  constraint brain_deletion_floors_version_check
    check (object_version > 0),
  constraint brain_deletion_floors_vault_not_blank
    check (length(trim(vault_id)) > 0),
  constraint brain_deletion_floors_object_not_blank
    check (length(trim(object_id)) > 0)
);

create index if not exists brain_deletion_floors_user_vault_idx
  on public.brain_deletion_floors (user_id, vault_id, object_id);

create table if not exists public.brain_deletion_device_acks (
  user_id uuid not null references auth.users(id) on delete cascade,
  vault_id text not null,
  object_id text not null,
  device_id text not null,
  object_version integer not null,
  observed_at timestamptz not null default now(),
  constraint brain_deletion_device_acks_pkey
    primary key (user_id, vault_id, object_id, device_id),
  constraint brain_deletion_device_acks_version_check
    check (object_version > 0),
  constraint brain_deletion_device_acks_device_fkey
    foreign key (user_id, vault_id, device_id)
    references public.brain_devices (user_id, vault_id, device_id)
    on delete cascade
);

create index if not exists brain_deletion_device_acks_lookup_idx
  on public.brain_deletion_device_acks
  (user_id, vault_id, object_id, object_version);

alter table public.brain_deletion_floors enable row level security;
alter table public.brain_deletion_device_acks enable row level security;

revoke all on table public.brain_deletion_floors from anon;
revoke all on table public.brain_deletion_floors from authenticated;
revoke all on table public.brain_deletion_device_acks from anon;
revoke all on table public.brain_deletion_device_acks from authenticated;

grant select on table public.brain_deletion_floors to authenticated;
grant select on table public.brain_deletion_device_acks to authenticated;

drop policy if exists brain_deletion_floors_select_own
  on public.brain_deletion_floors;
create policy brain_deletion_floors_select_own
  on public.brain_deletion_floors
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists brain_deletion_device_acks_select_own
  on public.brain_deletion_device_acks;
create policy brain_deletion_device_acks_select_own
  on public.brain_deletion_device_acks
  for select to authenticated
  using (user_id = auth.uid());

-- Batch acknowledgement after a successful Cloud pull. The caller must be an
-- authorized Brain device. Only technical deletion metadata is accepted.
create or replace function public.acknowledge_brain_tombstones(
  p_vault_id text,
  p_device_id text,
  p_auth_secret text,
  p_observations jsonb
) returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_item jsonb;
  v_object_id text;
  v_object_version integer;
  v_count integer := 0;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if not public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_device_id,
    p_auth_secret
  ) then
    raise exception 'device_not_authorized';
  end if;

  if p_observations is null or jsonb_typeof(p_observations) <> 'array' then
    raise exception 'invalid_observations';
  end if;

  for v_item in select value from jsonb_array_elements(p_observations)
  loop
    v_object_id := btrim(coalesce(v_item ->> 'object_id', ''));
    begin
      v_object_version := (v_item ->> 'object_version')::integer;
    exception when others then
      raise exception 'invalid_object_version';
    end;

    if v_object_id = '' or v_object_version <= 0 then
      raise exception 'invalid_observation';
    end if;

    -- Ack only a deletion that is currently provable either by the full
    -- tombstone or by an already-persisted deletion floor.
    if not exists (
      select 1
      from public.brain_objects bo
      where bo.user_id = v_user_id
        and bo.vault_id = btrim(p_vault_id)
        and bo.object_id = v_object_id
        and bo.is_deleted = true
        and bo.object_version >= v_object_version
    ) and not exists (
      select 1
      from public.brain_deletion_floors df
      where df.user_id = v_user_id
        and df.vault_id = btrim(p_vault_id)
        and df.object_id = v_object_id
        and df.object_version >= v_object_version
    ) then
      continue;
    end if;

    insert into public.brain_deletion_device_acks (
      user_id, vault_id, object_id, device_id, object_version, observed_at
    ) values (
      v_user_id,
      btrim(p_vault_id),
      v_object_id,
      btrim(p_device_id),
      v_object_version,
      now()
    )
    on conflict (user_id, vault_id, object_id, device_id)
    do update set
      object_version = greatest(
        public.brain_deletion_device_acks.object_version,
        excluded.object_version
      ),
      observed_at = now();

    v_count := v_count + 1;
  end loop;

  update public.brain_devices
  set last_seen_at = now()
  where user_id = v_user_id
    and vault_id = btrim(p_vault_id)
    and device_id = btrim(p_device_id)
    and status = 'authorized';

  return v_count;
end;
$$;

-- Candidate listing is metadata-only and fail-closed. An authorized offline
-- device keeps eligible=false until it observes/acks the deletion or is revoked.
create or replace function public.list_brain_remote_gc_candidates(
  p_vault_id text,
  p_requester_device_id text,
  p_requester_secret text,
  p_retention_days integer default 180,
  p_limit integer default 100
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
    raise exception 'not_authenticated';
  end if;

  if p_retention_days < 30 or p_retention_days > 3650 then
    raise exception 'invalid_retention_days';
  end if;

  if p_limit <= 0 or p_limit > 500 then
    raise exception 'invalid_limit';
  end if;

  if not public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_requester_device_id,
    p_requester_secret
  ) then
    raise exception 'requester_not_authorized';
  end if;

  with candidates as (
    select
      bo.object_id,
      bo.object_version,
      bo.updated_at as deleted_updated_at,
      bo.server_updated_at,
      (
        select count(*)::integer
        from public.brain_devices d
        where d.user_id = v_user_id
          and d.vault_id = btrim(p_vault_id)
          and d.status = 'authorized'
      ) as authorized_device_count,
      (
        select count(*)::integer
        from public.brain_devices d
        where d.user_id = v_user_id
          and d.vault_id = btrim(p_vault_id)
          and d.status = 'authorized'
          and exists (
            select 1
            from public.brain_deletion_device_acks a
            where a.user_id = d.user_id
              and a.vault_id = d.vault_id
              and a.device_id = d.device_id
              and a.object_id = bo.object_id
              and a.object_version >= bo.object_version
          )
      ) as acknowledged_device_count
    from public.brain_objects bo
    where bo.user_id = v_user_id
      and bo.vault_id = btrim(p_vault_id)
      and bo.is_deleted = true
      and bo.server_updated_at <= now() - (p_retention_days * interval '1 day')
    order by bo.server_updated_at asc, bo.object_id asc
    limit p_limit
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'object_id', c.object_id,
        'object_version', c.object_version,
        'deleted_updated_at', c.deleted_updated_at,
        'server_updated_at', c.server_updated_at,
        'authorized_device_count', c.authorized_device_count,
        'acknowledged_device_count', c.acknowledged_device_count,
        'eligible', (
          c.authorized_device_count > 0
          and c.acknowledged_device_count = c.authorized_device_count
        )
      )
    ),
    '[]'::jsonb
  ) into v_result
  from candidates c;

  return v_result;
end;
$$;

-- Atomic remote GC. The durable floor is committed in the SAME transaction as
-- deletion of the full encrypted tombstone.
create or replace function public.gc_brain_remote_tombstone(
  p_vault_id text,
  p_object_id text,
  p_requester_device_id text,
  p_requester_secret text,
  p_retention_days integer default 180
) returns boolean
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_object public.brain_objects;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_retention_days < 30 or p_retention_days > 3650 then
    raise exception 'invalid_retention_days';
  end if;

  if not public._brain_device_authorized_internal(
    v_user_id,
    p_vault_id,
    p_requester_device_id,
    p_requester_secret
  ) then
    raise exception 'requester_not_authorized';
  end if;

  select * into v_object
  from public.brain_objects bo
  where bo.user_id = v_user_id
    and bo.vault_id = btrim(p_vault_id)
    and bo.object_id = btrim(p_object_id)
  for update;

  if not found then
    -- Idempotent success if a floor already proves prior GC.
    return exists (
      select 1 from public.brain_deletion_floors df
      where df.user_id = v_user_id
        and df.vault_id = btrim(p_vault_id)
        and df.object_id = btrim(p_object_id)
    );
  end if;

  if not v_object.is_deleted then
    return false;
  end if;

  if v_object.server_updated_at > now() - (p_retention_days * interval '1 day') then
    return false;
  end if;

  if not exists (
    select 1
    from public.brain_devices d
    where d.user_id = v_user_id
      and d.vault_id = btrim(p_vault_id)
      and d.status = 'authorized'
  ) then
    return false;
  end if;

  if exists (
    select 1
    from public.brain_devices d
    where d.user_id = v_user_id
      and d.vault_id = btrim(p_vault_id)
      and d.status = 'authorized'
      and not exists (
        select 1
        from public.brain_deletion_device_acks a
        where a.user_id = d.user_id
          and a.vault_id = d.vault_id
          and a.device_id = d.device_id
          and a.object_id = v_object.object_id
          and a.object_version >= v_object.object_version
      )
  ) then
    return false;
  end if;

  insert into public.brain_deletion_floors (
    user_id,
    vault_id,
    object_id,
    object_version,
    deleted_at,
    compacted_at,
    source_server_updated_at
  ) values (
    v_user_id,
    v_object.vault_id,
    v_object.object_id,
    v_object.object_version,
    v_object.updated_at,
    now(),
    v_object.server_updated_at
  )
  on conflict (user_id, vault_id, object_id)
  do update set
    object_version = greatest(
      public.brain_deletion_floors.object_version,
      excluded.object_version
    ),
    deleted_at = case
      when excluded.object_version >= public.brain_deletion_floors.object_version
        then excluded.deleted_at
      else public.brain_deletion_floors.deleted_at
    end,
    compacted_at = now(),
    source_server_updated_at = excluded.source_server_updated_at;

  delete from public.brain_objects bo
  where bo.user_id = v_user_id
    and bo.vault_id = v_object.vault_id
    and bo.object_id = v_object.object_id
    and bo.is_deleted = true
    and bo.object_version = v_object.object_version;

  return found;
end;
$$;

-- After Phase 3, a deletion floor is authoritative. There is no undelete in
-- the current Brain model, so ACTIVE writes for a floored objectId are ignored.
-- Newer tombstones only advance the floor and never recreate brain_objects.
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
  v_user_id uuid := auth.uid();
  v_floor_version integer;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_vault_id is null or btrim(p_vault_id) = '' then
    raise exception 'invalid_vault_id';
  end if;
  if p_object_id is null or btrim(p_object_id) = '' then
    raise exception 'invalid_object_id';
  end if;
  if p_object_version <= 0 or p_crypto_version <= 0 or p_key_version <= 0 then
    raise exception 'invalid_version';
  end if;
  if p_encrypted_object is null then
    raise exception 'encrypted_object_required';
  end if;

  select df.object_version into v_floor_version
  from public.brain_deletion_floors df
  where df.user_id = v_user_id
    and df.vault_id = btrim(p_vault_id)
    and df.object_id = btrim(p_object_id);

  if v_floor_version is not null then
    if p_is_deleted and p_object_version > v_floor_version then
      update public.brain_deletion_floors
      set object_version = p_object_version,
          deleted_at = p_updated_at,
          compacted_at = now()
      where user_id = v_user_id
        and vault_id = btrim(p_vault_id)
        and object_id = btrim(p_object_id);
    end if;
    return;
  end if;

  insert into public.brain_objects (
    user_id, vault_id, object_id, object_version, crypto_version, key_version,
    is_deleted, encrypted_object, created_at, updated_at, server_updated_at
  ) values (
    v_user_id, btrim(p_vault_id), btrim(p_object_id), p_object_version,
    p_crypto_version, p_key_version, p_is_deleted, p_encrypted_object,
    p_created_at, p_updated_at, now()
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
  where public.brain_objects.object_version <= excluded.object_version
    and (
      public.brain_objects.is_deleted = false
      or excluded.is_deleted = true
    );
end;
$$;

-- Local compaction confirmation remains valid even after the full remote
-- tombstone has already been GCed, because the durable floor proves deletion.
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
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;
  if p_min_object_version <= 0 then
    raise exception 'invalid_version';
  end if;

  return exists (
    select 1 from public.brain_objects bo
    where bo.user_id = v_user_id
      and bo.vault_id = btrim(p_vault_id)
      and bo.object_id = btrim(p_object_id)
      and bo.is_deleted = true
      and bo.object_version >= p_min_object_version
  ) or exists (
    select 1 from public.brain_deletion_floors df
    where df.user_id = v_user_id
      and df.vault_id = btrim(p_vault_id)
      and df.object_id = btrim(p_object_id)
      and df.object_version >= p_min_object_version
  );
end;
$$;

revoke all on function public.acknowledge_brain_tombstones(text, text, text, jsonb) from public;
revoke all on function public.list_brain_remote_gc_candidates(text, text, text, integer, integer) from public;
revoke all on function public.gc_brain_remote_tombstone(text, text, text, text, integer) from public;
revoke all on function public.upsert_brain_object_e2ee(text, text, integer, integer, integer, boolean, jsonb, timestamptz, timestamptz) from public;
revoke all on function public.confirm_brain_tombstone_for_local_compaction(text, text, integer) from public;

grant execute on function public.acknowledge_brain_tombstones(text, text, text, jsonb) to authenticated;
grant execute on function public.list_brain_remote_gc_candidates(text, text, text, integer, integer) to authenticated;
grant execute on function public.gc_brain_remote_tombstone(text, text, text, text, integer) to authenticated;
grant execute on function public.upsert_brain_object_e2ee(text, text, integer, integer, integer, boolean, jsonb, timestamptz, timestamptz) to authenticated;
grant execute on function public.confirm_brain_tombstone_for_local_compaction(text, text, integer) to authenticated;

grant execute on function public.acknowledge_brain_tombstones(text, text, text, jsonb) to service_role;
grant execute on function public.list_brain_remote_gc_candidates(text, text, text, integer, integer) to service_role;
grant execute on function public.gc_brain_remote_tombstone(text, text, text, text, integer) to service_role;
grant execute on function public.upsert_brain_object_e2ee(text, text, integer, integer, integer, boolean, jsonb, timestamptz, timestamptz) to service_role;
grant execute on function public.confirm_brain_tombstone_for_local_compaction(text, text, integer) to service_role;

notify pgrst, 'reload schema';
