-- ============================================================
-- EVRYLUX — STUDIO / VALIDAÇÃO
-- Correção do SQL: sintaxe + RPCs
-- ============================================================

begin;

create table if not exists public.colab_validation_items (
  id uuid primary key default gen_random_uuid(),
  roadmap_item_id uuid not null unique,
  title text not null,
  description text,
  area text,
  assignee_user_id uuid references auth.users(id) on delete set null,

  validation_status text not null default 'untested'
    check (
      validation_status in (
        'untested',
        'testing',
        'validated',
        'review',
        'removal',
        'removed'
      )
    ),

  test_notes text,
  removal_reason text,

  created_by uuid not null
    references auth.users(id)
    on delete restrict,

  updated_by uuid
    references auth.users(id)
    on delete set null,

  test_started_at timestamptz,
  validated_at timestamptz,
  removed_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists colab_validation_status_idx
  on public.colab_validation_items (
    validation_status,
    updated_at desc
  );

create table if not exists public.colab_validation_votes (
  validation_item_id uuid not null
    references public.colab_validation_items(id)
    on delete cascade,

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  vote text not null
    check (
      vote in (
        'keep',
        'review',
        'remove'
      )
    ),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  primary key (
    validation_item_id,
    user_id
  )
);

alter table public.colab_validation_items
  enable row level security;

alter table public.colab_validation_votes
  enable row level security;

revoke all
on table public.colab_validation_items
from public, anon, authenticated;

revoke all
on table public.colab_validation_votes
from public, anon, authenticated;

-- ============================================================
-- LISTAR
-- ============================================================

drop function if exists public.list_colab_validation_items();

create function public.list_colab_validation_items()
returns table (
  id uuid,
  roadmap_item_id uuid,
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

    (
      select count(*)
      from public.colab_validation_votes v
      where
        v.validation_item_id = vi.id
        and v.vote = 'keep'
    )::bigint as vote_keep,

    (
      select count(*)
      from public.colab_validation_votes v
      where
        v.validation_item_id = vi.id
        and v.vote = 'review'
    )::bigint as vote_review,

    (
      select count(*)
      from public.colab_validation_votes v
      where
        v.validation_item_id = vi.id
        and v.vote = 'remove'
    )::bigint as vote_remove,

    (
      select v.vote
      from public.colab_validation_votes v
      where
        v.validation_item_id = vi.id
        and v.user_id = auth.uid()
      limit 1
    ) as my_vote

  from public.colab_validation_items vi

  where auth.uid() is not null

  order by
    case vi.validation_status
      when 'testing' then 1
      when 'untested' then 2
      when 'review' then 3
      when 'removal' then 4
      when 'validated' then 5
      when 'removed' then 6
      else 7
    end,
    vi.updated_at desc;
$$;

-- ============================================================
-- ROADMAP -> VALIDAÇÃO
-- ============================================================

drop function if exists public.send_roadmap_item_to_validation(
  uuid,
  text,
  text,
  text,
  uuid
);

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
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  if p_roadmap_item_id is null then
    raise exception 'Item do Roadmap inválido';
  end if;

  p_title :=
    trim(
      coalesce(
        p_title,
        ''
      )
    );

  if char_length(p_title) < 1 then
    raise exception 'Título obrigatório';
  end if;

  insert into public.colab_validation_items (
    roadmap_item_id,
    title,
    description,
    area,
    assignee_user_id,
    created_by,
    updated_by
  )
  values (
    p_roadmap_item_id,
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
    nullif(
      trim(
        coalesce(
          p_area,
          ''
        )
      ),
      ''
    ),
    p_assignee_user_id,
    auth.uid(),
    auth.uid()
  )

  on conflict (
    roadmap_item_id
  )

  do update set
    title =
      excluded.title,

    description =
      excluded.description,

    area =
      excluded.area,

    assignee_user_id =
      excluded.assignee_user_id,

    updated_by =
      auth.uid(),

    updated_at =
      now()

  returning id
  into v_id;

  return v_id;
end;
$$;

-- ============================================================
-- ATUALIZAR TESTE
-- ============================================================

drop function if exists public.update_colab_validation(
  uuid,
  text,
  text
);

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
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  if p_status not in (
    'untested',
    'testing',
    'validated',
    'review'
  ) then
    raise exception 'Status inválido';
  end if;

  update public.colab_validation_items
  set
    validation_status =
      p_status,

    test_notes =
      nullif(
        trim(
          coalesce(
            p_notes,
            ''
          )
        ),
        ''
      ),

    test_started_at =
      case
        when
          p_status = 'testing'
          and test_started_at is null
        then now()
        else test_started_at
      end,

    validated_at =
      case
        when p_status = 'validated'
        then now()

        when
          validation_status = 'validated'
          and p_status <> 'validated'
        then null

        else validated_at
      end,

    removed_at =
      null,

    updated_by =
      auth.uid(),

    updated_at =
      now()

  where id =
    p_validation_id;

  if not found then
    raise exception 'Item não encontrado';
  end if;

  return true;
end;
$$;

-- ============================================================
-- PROPOSTA DE REMOÇÃO
-- ============================================================

drop function if exists public.propose_colab_validation_removal(
  uuid,
  text
);

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
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  p_reason :=
    trim(
      coalesce(
        p_reason,
        ''
      )
    );

  if char_length(p_reason) < 5 then
    raise exception 'Explique o motivo da proposta';
  end if;

  update public.colab_validation_items
  set
    validation_status =
      'removal',

    removal_reason =
      p_reason,

    updated_by =
      auth.uid(),

    updated_at =
      now()

  where id =
    p_validation_id;

  if not found then
    raise exception 'Item não encontrado';
  end if;

  return true;
end;
$$;

-- ============================================================
-- VOTO
-- ============================================================

drop function if exists public.vote_colab_validation(
  uuid,
  text
);

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
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  if p_vote not in (
    'keep',
    'review',
    'remove'
  ) then
    raise exception 'Voto inválido';
  end if;

  if not exists (
    select 1
    from public.colab_validation_items
    where id = p_validation_id
  ) then
    raise exception 'Item não encontrado';
  end if;

  insert into public.colab_validation_votes (
    validation_item_id,
    user_id,
    vote
  )
  values (
    p_validation_id,
    auth.uid(),
    p_vote
  )

  on conflict (
    validation_item_id,
    user_id
  )

  do update set
    vote =
      excluded.vote,

    updated_at =
      now();

  return true;
end;
$$;

-- ============================================================
-- DECISÃO FINAL
-- ============================================================

create or replace function public.can_finalize_colab_validation()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    auth.uid() is not null
    and (
      coalesce(
        public.is_colab_owner(),
        false
      )
      or
      coalesce(
        public.is_colab_admin_role(),
        false
      )
    );
$$;

drop function if exists public.finalize_colab_validation(
  uuid,
  text
);

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
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  if not public.can_finalize_colab_validation() then
    raise exception 'Somente owner/admin pode confirmar a decisão final'
      using errcode = '42501';
  end if;

  if p_decision not in (
    'validated',
    'review',
    'removed'
  ) then
    raise exception 'Decisão inválida';
  end if;

  update public.colab_validation_items
  set
    validation_status =
      p_decision,

    validated_at =
      case
        when p_decision = 'validated'
        then now()
        else validated_at
      end,

    removed_at =
      case
        when p_decision = 'removed'
        then now()
        else null
      end,

    updated_by =
      auth.uid(),

    updated_at =
      now()

  where id =
    p_validation_id;

  if not found then
    raise exception 'Item não encontrado';
  end if;

  return true;
end;
$$;

-- ============================================================
-- PERMISSÕES DAS RPCs
-- ============================================================

revoke all
on function public.list_colab_validation_items()
from public, anon;

revoke all
on function public.send_roadmap_item_to_validation(
  uuid,
  text,
  text,
  text,
  uuid
)
from public, anon;

revoke all
on function public.update_colab_validation(
  uuid,
  text,
  text
)
from public, anon;

revoke all
on function public.propose_colab_validation_removal(
  uuid,
  text
)
from public, anon;

revoke all
on function public.vote_colab_validation(
  uuid,
  text
)
from public, anon;

revoke all
on function public.can_finalize_colab_validation()
from public, anon;

revoke all
on function public.finalize_colab_validation(
  uuid,
  text
)
from public, anon;

grant execute
on function public.list_colab_validation_items()
to authenticated;

grant execute
on function public.send_roadmap_item_to_validation(
  uuid,
  text,
  text,
  text,
  uuid
)
to authenticated;

grant execute
on function public.update_colab_validation(
  uuid,
  text,
  text
)
to authenticated;

grant execute
on function public.propose_colab_validation_removal(
  uuid,
  text
)
to authenticated;

grant execute
on function public.vote_colab_validation(
  uuid,
  text
)
to authenticated;

grant execute
on function public.can_finalize_colab_validation()
to authenticated;

grant execute
on function public.finalize_colab_validation(
  uuid,
  text
)
to authenticated;

commit;
