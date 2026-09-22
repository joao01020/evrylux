-- ============================================================
-- EVRYLUX — ROADMAP / MÚLTIPLOS RESPONSÁVEIS
-- Mantém assignee_user_id como responsável primário por
-- compatibilidade e adiciona uma relação N:N para os demais.
-- ============================================================

begin;

create table if not exists public.colab_roadmap_assignees (
  roadmap_item_id uuid not null
    references public.colab_roadmap_items(id)
    on delete cascade,

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  created_at timestamptz not null
    default now(),

  primary key (
    roadmap_item_id,
    user_id
  )
);

create index if not exists colab_roadmap_assignees_user_idx
  on public.colab_roadmap_assignees(
    user_id,
    roadmap_item_id
  );

alter table public.colab_roadmap_assignees
  enable row level security;

revoke all
on table public.colab_roadmap_assignees
from public, anon, authenticated;

-- Migra automaticamente os responsáveis únicos já existentes.
insert into public.colab_roadmap_assignees (
  roadmap_item_id,
  user_id
)
select
  id,
  assignee_user_id
from public.colab_roadmap_items
where assignee_user_id is not null
on conflict (
  roadmap_item_id,
  user_id
)
do nothing;

-- ============================================================
-- LISTAR RESPONSÁVEIS
-- ============================================================

drop function if exists public.list_colab_roadmap_assignees();

create function public.list_colab_roadmap_assignees()
returns table (
  roadmap_item_id uuid,
  user_id uuid
)
language sql
stable
security definer
set search_path = public
as $$
  select
    a.roadmap_item_id,
    a.user_id
  from public.colab_roadmap_assignees a
  where auth.uid() is not null
  order by
    a.roadmap_item_id,
    a.created_at;
$$;

-- ============================================================
-- DEFINIR TODOS OS RESPONSÁVEIS DE UM ITEM
-- ============================================================

drop function if exists public.set_colab_roadmap_assignees(
  uuid,
  uuid[]
);

create function public.set_colab_roadmap_assignees(
  p_roadmap_item_id uuid,
  p_user_ids uuid[]
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_primary uuid;
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.colab_roadmap_items
    where id = p_roadmap_item_id
  ) then
    raise exception 'Item do Roadmap não encontrado';
  end if;

  delete from public.colab_roadmap_assignees
  where roadmap_item_id =
    p_roadmap_item_id;

  insert into public.colab_roadmap_assignees (
    roadmap_item_id,
    user_id
  )
  select
    p_roadmap_item_id,
    selected_id
  from (
    select distinct
      unnest(
        coalesce(
          p_user_ids,
          array[]::uuid[]
        )
      ) as selected_id
  ) ids
  where selected_id is not null;

  v_primary =
    case
      when
        coalesce(
          array_length(
            p_user_ids,
            1
          ),
          0
        ) > 0
      then p_user_ids[1]
      else null
    end;

  -- Mantém o campo legado sincronizado com o primeiro selecionado.
  update public.colab_roadmap_items
  set
    assignee_user_id =
      v_primary,
    updated_at =
      now()
  where id =
    p_roadmap_item_id;

  return true;
end;
$$;

revoke all
on function public.list_colab_roadmap_assignees()
from public, anon;

revoke all
on function public.set_colab_roadmap_assignees(
  uuid,
  uuid[]
)
from public, anon;

grant execute
on function public.list_colab_roadmap_assignees()
to authenticated;

grant execute
on function public.set_colab_roadmap_assignees(
  uuid,
  uuid[]
)
to authenticated;

commit;

notify pgrst, 'reload schema';
