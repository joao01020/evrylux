begin;

create table if not exists public.brain_vault_registry (
  user_id uuid primary key references auth.users(id) on delete cascade,
  vault_id text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.brain_vault_registry enable row level security;

revoke all on table public.brain_vault_registry from anon;
revoke all on table public.brain_vault_registry from authenticated;

create or replace function public.discover_brain_vault()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_vault_id text;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  select r.vault_id
  into v_vault_id
  from public.brain_vault_registry r
  where r.user_id = v_user_id;

  if v_vault_id is not null then
    return v_vault_id;
  end if;

  select d.vault_id
  into v_vault_id
  from public.brain_devices d
  where d.user_id = v_user_id
  order by
    coalesce(d.last_seen_at, d.authorized_at, d.created_at) desc nulls last,
    d.created_at desc
  limit 1;

  if v_vault_id is null then
    select o.vault_id
    into v_vault_id
    from public.brain_objects o
    where o.user_id = v_user_id
    order by o.updated_at desc nulls last
    limit 1;
  end if;

  if v_vault_id is not null then
    insert into public.brain_vault_registry(user_id, vault_id)
    values (v_user_id, v_vault_id)
    on conflict (user_id) do nothing;

    select r.vault_id
    into v_vault_id
    from public.brain_vault_registry r
    where r.user_id = v_user_id;
  end if;

  return v_vault_id;
end;
$$;

create or replace function public.claim_brain_vault(
  p_proposed_vault_id text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_vault_id text;
  v_can_bootstrap boolean := false;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if nullif(trim(p_proposed_vault_id), '') is null
     or length(trim(p_proposed_vault_id)) > 300
     or trim(p_proposed_vault_id) !~ '^vault_[A-Za-z0-9_-]+$' then
    raise exception 'invalid_vault_id';
  end if;

  perform pg_advisory_xact_lock(
    hashtext('brain-vault:' || v_user_id::text)
  );

  v_vault_id := public.discover_brain_vault();

  if v_vault_id is null then
    v_vault_id := trim(p_proposed_vault_id);

    insert into public.brain_vault_registry(
      user_id,
      vault_id,
      created_at,
      updated_at
    )
    values (
      v_user_id,
      v_vault_id,
      now(),
      now()
    )
    on conflict (user_id) do nothing;

    select r.vault_id
    into v_vault_id
    from public.brain_vault_registry r
    where r.user_id = v_user_id;
  end if;

  select
    not exists (
      select 1
      from public.brain_devices d
      where d.user_id = v_user_id
        and d.vault_id = v_vault_id
    )
    and
    not exists (
      select 1
      from public.brain_objects o
      where o.user_id = v_user_id
        and o.vault_id = v_vault_id
    )
  into v_can_bootstrap;

  update public.brain_vault_registry
  set updated_at = now()
  where user_id = v_user_id;

  return jsonb_build_object(
    'vault_id', v_vault_id,
    'can_bootstrap', v_can_bootstrap
  );
end;
$$;

revoke all on function public.discover_brain_vault() from public;
revoke all on function public.discover_brain_vault() from anon;
grant execute on function public.discover_brain_vault() to authenticated;

revoke all on function public.claim_brain_vault(text) from public;
revoke all on function public.claim_brain_vault(text) from anon;
grant execute on function public.claim_brain_vault(text) to authenticated;

commit;
