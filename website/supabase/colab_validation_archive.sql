begin;

-- EVRYLUX — Remover da lista de Validação via soft delete.
-- Preserva histórico, votos e anexos.

alter table public.colab_validation_items
  add column if not exists archived_at timestamptz;

alter table public.colab_validation_items
  add column if not exists archived_by uuid
  references auth.users(id)
  on delete set null;

-- Lista somente itens ativos.
drop function if exists public.list_colab_validation_items();

create function public.list_colab_validation_items()
returns table (
  id uuid,
  roadmap_item_id uuid,
  source_type text,
  title text,
  description text,
  area text,
  assignee_user_id uuid,
  validation_status text,
  test_notes text,
  removal_reason text,
  created_by uuid,
  test_started_at timestamptz,
  validated_at timestamptz,
  removed_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  vote_keep bigint,
  vote_review bigint,
  vote_remove bigint,
  my_vote text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    vi.id,
    vi.roadmap_item_id,
    vi.source_type,
    vi.title,
    vi.description,
    vi.area,
    vi.assignee_user_id,
    vi.validation_status,
    vi.test_notes,
    vi.removal_reason,
    vi.created_by,
    vi.test_started_at,
    vi.validated_at,
    vi.removed_at,
    vi.created_at,
    vi.updated_at,
    (select count(*) from public.colab_validation_votes v where v.validation_item_id=vi.id and v.vote='keep')::bigint,
    (select count(*) from public.colab_validation_votes v where v.validation_item_id=vi.id and v.vote='review')::bigint,
    (select count(*) from public.colab_validation_votes v where v.validation_item_id=vi.id and v.vote='remove')::bigint,
    (select v.vote from public.colab_validation_votes v where v.validation_item_id=vi.id and v.user_id=auth.uid() limit 1)
  from public.colab_validation_items vi
  where
    auth.uid() is not null
    and vi.archived_at is null
  order by vi.updated_at desc;
$$;

-- Arquiva item sem apagar seus dados.
drop function if exists public.archive_colab_validation_item(uuid);

create function public.archive_colab_validation_item(
  p_validation_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_created_by uuid;
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária'
      using errcode='42501';
  end if;

  select vi.created_by
  into v_created_by
  from public.colab_validation_items vi
  where
    vi.id=p_validation_id
    and vi.archived_at is null;

  if v_created_by is null then
    raise exception 'Item de validação não encontrado';
  end if;

  if
    v_created_by <> auth.uid()
    and not coalesce(public.is_colab_owner(),false)
    and not coalesce(public.is_colab_admin_role(),false)
  then
    raise exception 'Você não tem permissão para remover este item da lista'
      using errcode='42501';
  end if;

  update public.colab_validation_items
  set
    archived_at=now(),
    archived_by=auth.uid(),
    updated_by=auth.uid(),
    updated_at=now()
  where id=p_validation_id;

  return true;
end;
$$;

-- Se um item do Roadmap arquivado for enviado novamente, reativa a mesma validação.
drop function if exists public.send_roadmap_item_to_validation(uuid,text,text,text,uuid);

create function public.send_roadmap_item_to_validation(
  p_roadmap_item_id uuid,
  p_title text,
  p_description text default null,
  p_area text default null,
  p_assignee_user_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária' using errcode='42501';
  end if;

  insert into public.colab_validation_items (
    roadmap_item_id,source_type,title,description,area,assignee_user_id,created_by,updated_by
  )
  values (
    p_roadmap_item_id,'roadmap',trim(p_title),
    nullif(trim(coalesce(p_description,'')),''),
    nullif(trim(coalesce(p_area,'')),''),
    p_assignee_user_id,auth.uid(),auth.uid()
  )
  on conflict (roadmap_item_id)
  do update set
    source_type='roadmap',
    title=excluded.title,
    description=excluded.description,
    area=excluded.area,
    assignee_user_id=excluded.assignee_user_id,
    archived_at=null,
    archived_by=null,
    updated_by=auth.uid(),
    updated_at=now()
  returning id into v_id;

  return v_id;
end;
$$;

grant execute on function public.list_colab_validation_items() to authenticated;
grant execute on function public.archive_colab_validation_item(uuid) to authenticated;
grant execute on function public.send_roadmap_item_to_validation(uuid,text,text,text,uuid) to authenticated;

commit;
