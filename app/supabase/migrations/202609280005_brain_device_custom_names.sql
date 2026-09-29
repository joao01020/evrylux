-- EVRYLUX
-- Friendly names for Brain devices.
--
-- The generated device_name remains the technical/default name.
-- custom_name is user-owned and is never overwritten by device registration.

alter table public.brain_devices
  add column if not exists custom_name text;

comment on column public.brain_devices.custom_name is
  'Optional user-defined friendly label for a Brain device.';

create or replace function public.rename_brain_device(
  p_vault_id text,
  p_requester_device_id text,
  p_requester_secret text,
  p_target_device_id text,
  p_device_name text
)
returns text
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_user_id uuid := auth.uid();
  v_clean_name text := btrim(coalesce(p_device_name, ''));
  v_rows integer := 0;
begin
  if v_user_id is null then
    raise exception 'unauthenticated';
  end if;

  if nullif(btrim(coalesce(p_vault_id, '')), '') is null
     or nullif(btrim(coalesce(p_requester_device_id, '')), '') is null
     or nullif(btrim(coalesce(p_requester_secret, '')), '') is null
     or nullif(btrim(coalesce(p_target_device_id, '')), '') is null then
    raise exception 'invalid_device_request';
  end if;

  if char_length(v_clean_name) < 2
     or char_length(v_clean_name) > 80 then
    raise exception 'invalid_device_name';
  end if;

  if not public._brain_device_authorized_internal(
    v_user_id,
    btrim(p_vault_id),
    btrim(p_requester_device_id),
    p_requester_secret
  ) then
    raise exception 'requester_not_authorized';
  end if;

  update public.brain_devices d
  set custom_name = v_clean_name
  where d.user_id = v_user_id
    and d.vault_id = btrim(p_vault_id)
    and d.device_id = btrim(p_target_device_id)
    and d.status <> 'revoked';

  get diagnostics v_rows = row_count;

  if v_rows <> 1 then
    raise exception 'target_device_not_found_or_revoked';
  end if;

  return v_clean_name;
end;
$$;

create or replace function public.list_brain_device_custom_names(
  p_vault_id text,
  p_requester_device_id text,
  p_requester_secret text
)
returns jsonb
language plpgsql
stable
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
    btrim(p_vault_id),
    btrim(p_requester_device_id),
    p_requester_secret
  ) then
    raise exception 'requester_not_authorized';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'device_id', d.device_id,
        'custom_name', d.custom_name
      )
      order by d.created_at asc
    ) filter (
      where nullif(btrim(coalesce(d.custom_name, '')), '') is not null
    ),
    '[]'::jsonb
  )
  into v_result
  from public.brain_devices d
  where d.user_id = v_user_id
    and d.vault_id = btrim(p_vault_id);

  return v_result;
end;
$$;

revoke all on function public.rename_brain_device(
  text, text, text, text, text
) from public;

revoke all on function public.rename_brain_device(
  text, text, text, text, text
) from anon;

grant execute on function public.rename_brain_device(
  text, text, text, text, text
) to authenticated;

revoke all on function public.list_brain_device_custom_names(
  text, text, text
) from public;

revoke all on function public.list_brain_device_custom_names(
  text, text, text
) from anon;

grant execute on function public.list_brain_device_custom_names(
  text, text, text
) to authenticated;
