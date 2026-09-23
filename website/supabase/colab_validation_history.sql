begin;

create table if not exists public.colab_validation_items (
  id uuid primary key default gen_random_uuid(),
  roadmap_item_id uuid unique,
  source_type text not null default 'roadmap'
    check (source_type in ('roadmap','direct')),
  title text not null,
  description text,
  area text,
  assignee_user_id uuid references auth.users(id) on delete set null,
  validation_status text not null default 'untested'
    check (validation_status in ('untested','testing','validated','review','removal','removed')),
  test_notes text,
  removal_reason text,
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_by uuid references auth.users(id) on delete set null,
  test_started_at timestamptz,
  validated_at timestamptz,
  removed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.colab_validation_items
  alter column roadmap_item_id drop not null;

alter table public.colab_validation_items
  add column if not exists source_type text;

update public.colab_validation_items
set source_type =
  case
    when roadmap_item_id is null then 'direct'
    else 'roadmap'
  end
where source_type is null;

alter table public.colab_validation_items
  alter column source_type set default 'roadmap';

alter table public.colab_validation_items
  alter column source_type set not null;

create table if not exists public.colab_validation_votes (
  validation_item_id uuid not null
    references public.colab_validation_items(id) on delete cascade,
  user_id uuid not null
    references auth.users(id) on delete cascade,
  vote text not null check (vote in ('keep','review','remove')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (validation_item_id, user_id)
);

alter table public.colab_validation_items enable row level security;
alter table public.colab_validation_votes enable row level security;

revoke all on table public.colab_validation_items from public, anon, authenticated;
revoke all on table public.colab_validation_votes from public, anon, authenticated;

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
  where auth.uid() is not null
  order by vi.updated_at desc;
$$;

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
    updated_by=auth.uid(),
    updated_at=now()
  returning id into v_id;

  return v_id;
end;
$$;

drop function if exists public.create_colab_validation_item(text,text,text,uuid);

create function public.create_colab_validation_item(
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

  p_title := trim(coalesce(p_title,''));

  if char_length(p_title) < 2 then
    raise exception 'Informe um nome válido';
  end if;

  insert into public.colab_validation_items (
    roadmap_item_id,source_type,title,description,area,assignee_user_id,
    validation_status,created_by,updated_by
  )
  values (
    null,'direct',p_title,
    nullif(trim(coalesce(p_description,'')),''),
    nullif(trim(coalesce(p_area,'')),''),
    p_assignee_user_id,
    'untested',auth.uid(),auth.uid()
  )
  returning id into v_id;

  return v_id;
end;
$$;

drop function if exists public.update_colab_validation(uuid,text,text);

create function public.update_colab_validation(
  p_validation_id uuid,
  p_status text,
  p_notes text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária' using errcode='42501';
  end if;

  if p_status not in ('untested','testing','validated','review') then
    raise exception 'Status inválido';
  end if;

  update public.colab_validation_items
  set
    validation_status=p_status,
    test_notes=nullif(trim(coalesce(p_notes,'')),''),
    test_started_at=case when p_status='testing' and test_started_at is null then now() else test_started_at end,
    validated_at=case when p_status='validated' then now() else validated_at end,
    removed_at=null,
    updated_by=auth.uid(),
    updated_at=now()
  where id=p_validation_id;

  return true;
end;
$$;

drop function if exists public.propose_colab_validation_removal(uuid,text);

create function public.propose_colab_validation_removal(
  p_validation_id uuid,
  p_reason text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária' using errcode='42501';
  end if;

  update public.colab_validation_items
  set
    validation_status='removal',
    removal_reason=trim(p_reason),
    updated_by=auth.uid(),
    updated_at=now()
  where id=p_validation_id;

  return true;
end;
$$;

drop function if exists public.vote_colab_validation(uuid,text);

create function public.vote_colab_validation(
  p_validation_id uuid,
  p_vote text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária' using errcode='42501';
  end if;

  insert into public.colab_validation_votes(validation_item_id,user_id,vote)
  values (p_validation_id,auth.uid(),p_vote)
  on conflict (validation_item_id,user_id)
  do update set vote=excluded.vote,updated_at=now();

  return true;
end;
$$;

create or replace function public.can_finalize_colab_validation()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null
    and (
      coalesce(public.is_colab_owner(),false)
      or coalesce(public.is_colab_admin_role(),false)
    );
$$;

drop function if exists public.finalize_colab_validation(uuid,text);

create function public.finalize_colab_validation(
  p_validation_id uuid,
  p_decision text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.can_finalize_colab_validation() then
    raise exception 'Somente owner/admin pode confirmar a decisão final' using errcode='42501';
  end if;

  update public.colab_validation_items
  set
    validation_status=p_decision,
    validated_at=case when p_decision='validated' then now() else validated_at end,
    removed_at=case when p_decision='removed' then now() else null end,
    updated_by=auth.uid(),
    updated_at=now()
  where id=p_validation_id;

  return true;
end;
$$;

grant execute on function public.list_colab_validation_items() to authenticated;
grant execute on function public.send_roadmap_item_to_validation(uuid,text,text,text,uuid) to authenticated;
grant execute on function public.create_colab_validation_item(text,text,text,uuid) to authenticated;
grant execute on function public.update_colab_validation(uuid,text,text) to authenticated;
grant execute on function public.propose_colab_validation_removal(uuid,text) to authenticated;
grant execute on function public.vote_colab_validation(uuid,text) to authenticated;
grant execute on function public.can_finalize_colab_validation() to authenticated;
grant execute on function public.finalize_colab_validation(uuid,text) to authenticated;


-- ============================================================
-- EDITAR DADOS DA FUNÇÃO NA VALIDAÇÃO
-- ============================================================

drop function if exists public.edit_colab_validation_item(
  uuid,text,text,text,uuid
);

create function public.edit_colab_validation_item(
  p_validation_id uuid,
  p_title text,
  p_description text default null,
  p_area text default null,
  p_assignee_user_id uuid default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  p_title := trim(coalesce(p_title,''));

  if char_length(p_title) < 2 then
    raise exception 'Informe um nome válido';
  end if;

  update public.colab_validation_items
  set
    title = p_title,
    description = nullif(trim(coalesce(p_description,'')),''),
    area = nullif(trim(coalesce(p_area,'')),''),
    assignee_user_id = p_assignee_user_id,
    updated_by = auth.uid(),
    updated_at = now()
  where id = p_validation_id;

  if not found then
    raise exception 'Item não encontrado';
  end if;

  return true;
end;
$$;

grant execute
on function public.edit_colab_validation_item(
  uuid,text,text,text,uuid
)
to authenticated;


-- ============================================================
-- EVRYLUX — ETAPAS / HISTÓRICO DA VALIDAÇÃO
-- ============================================================

create table if not exists public.colab_validation_history (
  id uuid primary key default gen_random_uuid(),

  validation_item_id uuid not null
    references public.colab_validation_items(id)
    on delete cascade,

  phase text not null
    check (
      phase in (
        'planning',
        'implementation',
        'test',
        'fix',
        'retest',
        'validation',
        'review',
        'removal',
        'observation'
      )
    ),

  title text not null,

  description text,

  result text not null default 'info'
    check (
      result in (
        'pending',
        'success',
        'partial',
        'problem',
        'info'
      )
    ),

  created_by uuid not null
    references auth.users(id)
    on delete restrict,

  created_at timestamptz not null
    default now()
);

create index if not exists
  colab_validation_history_item_created_idx
on public.colab_validation_history (
  validation_item_id,
  created_at asc
);

alter table
  public.colab_validation_history
enable row level security;

revoke all
on table public.colab_validation_history
from public, anon, authenticated;


drop function if exists
  public.list_colab_validation_history();

create function
  public.list_colab_validation_history()
returns table (
  id uuid,
  validation_item_id uuid,
  phase text,
  title text,
  description text,
  result text,
  created_by uuid,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    h.id,
    h.validation_item_id,
    h.phase,
    h.title,
    h.description,
    h.result,
    h.created_by,
    h.created_at
  from public.colab_validation_history h
  join public.colab_validation_items vi
    on vi.id =
       h.validation_item_id
  where auth.uid() is not null
  order by
    h.validation_item_id,
    h.created_at asc;
$$;


drop function if exists
  public.add_colab_validation_history_entry(
    uuid,
    text,
    text,
    text,
    text
  );

create function
  public.add_colab_validation_history_entry(
    p_validation_id uuid,
    p_phase text,
    p_title text,
    p_description text default null,
    p_result text default 'info'
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
    raise exception
      'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  p_phase :=
    trim(
      coalesce(
        p_phase,
        ''
      )
    );

  p_title :=
    trim(
      coalesce(
        p_title,
        ''
      )
    );

  p_result :=
    trim(
      coalesce(
        p_result,
        'info'
      )
    );

  if p_phase not in (
    'planning',
    'implementation',
    'test',
    'fix',
    'retest',
    'validation',
    'review',
    'removal',
    'observation'
  ) then
    raise exception
      'Fase inválida';
  end if;

  if p_result not in (
    'pending',
    'success',
    'partial',
    'problem',
    'info'
  ) then
    raise exception
      'Resultado inválido';
  end if;

  if char_length(
    p_title
  ) < 2 then
    raise exception
      'Informe um título válido para a etapa';
  end if;

  if not exists (
    select 1
    from public.colab_validation_items
    where id =
      p_validation_id
  ) then
    raise exception
      'Item de validação não encontrado';
  end if;

  insert into
    public.colab_validation_history (
      validation_item_id,
      phase,
      title,
      description,
      result,
      created_by
    )
  values (
    p_validation_id,
    p_phase,
    p_title,
    nullif(
      trim(
        coalesce(
          p_description,
          ''
        )
      ),
      ''
    ),
    p_result,
    auth.uid()
  )
  returning id
  into v_id;

  update
    public.colab_validation_items
  set
    updated_by =
      auth.uid(),
    updated_at =
      now()
  where id =
    p_validation_id;

  return v_id;
end;
$$;


grant execute
on function
  public.list_colab_validation_history()
to authenticated;

grant execute
on function
  public.add_colab_validation_history_entry(
    uuid,
    text,
    text,
    text,
    text
  )
to authenticated;


commit;
