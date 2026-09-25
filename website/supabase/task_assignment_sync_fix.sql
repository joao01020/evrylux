begin;

-- ============================================================
-- EVRYLUX — CORREÇÃO DE FONTE DE VERDADE DAS TAREFAS
-- ============================================================
--
-- Roadmap atual usa:
--   colab_roadmap_items.assignee_user_id
--
-- Dashboard antigo usava:
--   colab_roadmap_assignees
--
-- Agora Dashboard/Header/Minhas tarefas usam a mesma fonte canônica.
--

create index if not exists
  colab_roadmap_items_assignee_status_stage_idx
on public.colab_roadmap_items (
  assignee_user_id,
  status,
  stage
);

-- Encerra notificações antigas que já não correspondem ao responsável atual.
update
  public.colab_task_notifications n
set
  is_read = true,
  read_at = coalesce(
    n.read_at,
    now()
  )
from
  public.colab_roadmap_items r
where
  r.id =
    n.roadmap_item_id
  and n.is_read =
    false
  and r.assignee_user_id
    is distinct from
    n.user_id;


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
    coalesce(
      r.progress,
      0
    )::integer,
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

  from
    public.colab_roadmap_items r

  left join lateral (
    select
      n.id,
      n.is_read,
      n.created_at,
      n.assigned_by
    from
      public.colab_task_notifications n
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

  left join
    public.member_profiles assigned_profile
      on assigned_profile.user_id =
        latest_notification.assigned_by

  left join
    auth.users assigned_user
      on assigned_user.id =
        latest_notification.assigned_by

  where
    auth.uid() is not null
    and r.assignee_user_id =
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

    case
      r.stage
      when 'now' then 0
      when 'next' then 1
      when 'later' then 2
      else 3
    end,

    case
      when r.due_date is null
      then 1
      else 0
    end,

    r.due_date asc nulls last,

    r.updated_at desc;
$$;


revoke all
on function
  public.list_my_colab_roadmap_tasks()
from
  public,
  anon;

grant execute
on function
  public.list_my_colab_roadmap_tasks()
to authenticated;

commit;

notify pgrst, 'reload schema';
