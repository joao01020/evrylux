-- ============================================================
-- EVRYLUX — ROADMAP / CONVITES DE TAREFAS + INBOX NO DASHBOARD
-- ============================================================
--
-- Fluxo:
-- 1. alguém adiciona um colaborador aos responsáveis do Roadmap;
-- 2. set_colab_roadmap_assignees detecta apenas os NOVOS responsáveis;
-- 3. cria uma notificação persistente para cada novo responsável;
-- 4. Supabase Realtime entrega o INSERT para o usuário conectado;
-- 5. Dashboard mostra card + som;
-- 6. ao abrir o Dashboard futuramente, a tarefa continua em "Minhas tarefas".
--
-- ============================================================

begin;

create table if not exists public.colab_task_notifications (
  id uuid primary key
    default gen_random_uuid(),

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  roadmap_item_id uuid not null
    references public.colab_roadmap_items(id)
    on delete cascade,

  assigned_by uuid
    references auth.users(id)
    on delete set null,

  notification_type text not null
    default 'roadmap_assignment'
    check (
      notification_type in (
        'roadmap_assignment'
      )
    ),

  message text not null
    default 'Você foi convidado(a) para realizar esta tarefa.',

  is_read boolean not null
    default false,

  read_at timestamptz,

  created_at timestamptz not null
    default now()
);

create index if not exists
  colab_task_notifications_user_created_idx
on public.colab_task_notifications (
  user_id,
  created_at desc
);

create index if not exists
  colab_task_notifications_roadmap_idx
on public.colab_task_notifications (
  roadmap_item_id,
  user_id
);

alter table public.colab_task_notifications
  enable row level security;

revoke all
on table public.colab_task_notifications
from public, anon, authenticated;

grant select
on table public.colab_task_notifications
to authenticated;

drop policy if exists
  colab_task_notifications_select_own
on public.colab_task_notifications;

create policy
  colab_task_notifications_select_own
on public.colab_task_notifications
for select
to authenticated
using (
  user_id =
    auth.uid()
);

-- Realtime precisa que a tabela esteja na publication.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname =
      'supabase_realtime'
      and schemaname =
        'public'
      and tablename =
        'colab_task_notifications'
  ) then
    alter publication
      supabase_realtime
    add table
      public.colab_task_notifications;
  end if;
end $$;

-- ============================================================
-- LISTAR TAREFAS DO USUÁRIO
-- ============================================================

drop function if exists
  public.list_my_colab_roadmap_tasks();

create function
  public.list_my_colab_roadmap_tasks()
returns table (
  id uuid,
  title text,
  description text,
  area text,
  stage text,
  status text,
  priority text,
  progress integer,
  due_date date,
  notification_id uuid,
  notification_is_read boolean,
  notification_created_at timestamptz,
  assigned_by_user_id uuid,
  assigned_by_name text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    r.id,
    r.title,
    r.description,
    r.area,
    r.stage,
    r.status,
    r.priority,
    coalesce(r.progress,0)::integer,
    r.due_date,

    latest_notification.id,
    coalesce(
      latest_notification.is_read,
      true
    ),
    latest_notification.created_at,
    latest_notification.assigned_by,

    coalesce(
      nullif(
        trim(
          assigned_profile.display_name
        ),
        ''
      ),
      assigned_user.email,
      null
    ) as assigned_by_name

  from public.colab_roadmap_assignees a

  join public.colab_roadmap_items r
    on r.id =
      a.roadmap_item_id

  left join lateral (
    select
      n.id,
      n.is_read,
      n.created_at,
      n.assigned_by
    from public.colab_task_notifications n
    where
      n.user_id =
        auth.uid()
      and n.roadmap_item_id =
        r.id
    order by
      n.created_at desc
    limit 1
  ) latest_notification
    on true

  left join public.member_profiles assigned_profile
    on assigned_profile.user_id =
      latest_notification.assigned_by

  left join auth.users assigned_user
    on assigned_user.id =
      latest_notification.assigned_by

  where
    auth.uid() is not null
    and a.user_id =
      auth.uid()
    and r.status <>
      'done'

  order by
    case
      when
        latest_notification.id is not null
        and latest_notification.is_read = false
      then 0
      else 1
    end,
    case r.stage
      when 'now' then 0
      when 'next' then 1
      when 'later' then 2
      else 3
    end,
    r.updated_at desc;
$$;

revoke all
on function
  public.list_my_colab_roadmap_tasks()
from public, anon;

grant execute
on function
  public.list_my_colab_roadmap_tasks()
to authenticated;

-- ============================================================
-- MARCAR NOTIFICAÇÃO COMO LIDA
-- ============================================================

drop function if exists
  public.mark_colab_task_notification_read(uuid);

create function
  public.mark_colab_task_notification_read(
    p_notification_id uuid
  )
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception
      'Sessão autenticada necessária'
      using errcode='42501';
  end if;

  update public.colab_task_notifications
  set
    is_read =
      true,
    read_at =
      coalesce(
        read_at,
        now()
      )
  where
    id =
      p_notification_id
    and user_id =
      auth.uid();

  return found;
end;
$$;

revoke all
on function
  public.mark_colab_task_notification_read(uuid)
from public, anon;

grant execute
on function
  public.mark_colab_task_notification_read(uuid)
to authenticated;

-- ============================================================
-- SUBSTITUI RPC DE RESPONSÁVEIS
-- Agora detecta quais pessoas foram adicionadas NESTA alteração
-- e cria notificação apenas para essas pessoas.
-- ============================================================

drop function if exists
  public.set_colab_roadmap_assignees(
    uuid,
    uuid[]
  );

create function
  public.set_colab_roadmap_assignees(
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

  v_old_user_ids uuid[];

  v_new_user_ids uuid[];

  v_added_user_id uuid;
begin
  if auth.uid() is null then
    raise exception
      'Sessão autenticada necessária'
      using errcode='42501';
  end if;

  if not exists (
    select 1
    from public.colab_roadmap_items
    where id =
      p_roadmap_item_id
  ) then
    raise exception
      'Item do Roadmap não encontrado';
  end if;

  select
    coalesce(
      array_agg(
        a.user_id
        order by a.created_at
      ),
      array[]::uuid[]
    )
  into
    v_old_user_ids
  from public.colab_roadmap_assignees a
  where
    a.roadmap_item_id =
      p_roadmap_item_id;

  select
    coalesce(
      array_agg(
        distinct selected_id
      ),
      array[]::uuid[]
    )
  into
    v_new_user_ids
  from (
    select
      unnest(
        coalesce(
          p_user_ids,
          array[]::uuid[]
        )
      ) as selected_id
  ) normalized
  where
    selected_id is not null;

  delete from
    public.colab_roadmap_assignees
  where
    roadmap_item_id =
      p_roadmap_item_id;

  insert into
    public.colab_roadmap_assignees (
      roadmap_item_id,
      user_id
    )
  select
    p_roadmap_item_id,
    selected_id
  from
    unnest(
      v_new_user_ids
    ) selected_id
  on conflict (
    roadmap_item_id,
    user_id
  )
  do nothing;

  v_primary =
    case
      when
        coalesce(
          array_length(
            p_user_ids,
            1
          ),
          0
        ) >
        0
      then
        p_user_ids[1]
      else
        null
    end;

  update
    public.colab_roadmap_items
  set
    assignee_user_id =
      v_primary,
    updated_at =
      now()
  where
    id =
      p_roadmap_item_id;

  -- Notifica somente responsáveis que não existiam antes.
  foreach
    v_added_user_id
  in array
    v_new_user_ids
  loop
    if
      not (
        v_added_user_id =
        any(
          v_old_user_ids
        )
      )
      and
      v_added_user_id <>
        auth.uid()
    then
      insert into
        public.colab_task_notifications (
          user_id,
          roadmap_item_id,
          assigned_by,
          notification_type,
          message
        )
      values (
        v_added_user_id,
        p_roadmap_item_id,
        auth.uid(),
        'roadmap_assignment',
        'Você foi convidado(a) para realizar esta tarefa.'
      );
    end if;
  end loop;

  return true;
end;
$$;

revoke all
on function
  public.set_colab_roadmap_assignees(
    uuid,
    uuid[]
  )
from public, anon;

grant execute
on function
  public.set_colab_roadmap_assignees(
    uuid,
    uuid[]
  )
to authenticated;

commit;

notify pgrst, 'reload schema';
