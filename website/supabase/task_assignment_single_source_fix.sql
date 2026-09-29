begin;

-- ============================================================
-- EVRYLUX — RESPONSÁVEL ÚNICO / FONTE ÚNICA DE VERDADE
-- ============================================================
--
-- FONTE CANÔNICA:
--   public.colab_roadmap_items.assignee_user_id
--
-- OBJETIVO:
-- - Dashboard mostra somente tarefas marcadas para a conta atual;
-- - tarefa marcada para Brenda não aparece para João;
-- - tarefa marcada para João não aparece para Brenda;
-- - tabela auxiliar colab_roadmap_assignees deixa de ficar divergente;
-- - código antigo que ainda lê a tabela auxiliar continua funcionando.
--
-- IMPORTANTE:
-- Este projeto está usando responsável único por item.
-- ============================================================


-- ============================================================
-- 1. LIMPAR VÍNCULOS AUXILIARES INCORRETOS
-- ============================================================

delete from
  public.colab_roadmap_assignees a
using
  public.colab_roadmap_items r
where
  a.roadmap_item_id = r.id
  and (
    r.assignee_user_id is null
    or a.user_id is distinct from r.assignee_user_id
  );


-- ============================================================
-- 2. CRIAR VÍNCULOS AUXILIARES QUE ESTÃO FALTANDO
-- ============================================================

insert into
  public.colab_roadmap_assignees (
    roadmap_item_id,
    user_id
  )
select
  r.id,
  r.assignee_user_id
from
  public.colab_roadmap_items r
where
  r.assignee_user_id is not null
  and not exists (
    select
      1
    from
      public.colab_roadmap_assignees a
    where
      a.roadmap_item_id = r.id
      and a.user_id = r.assignee_user_id
  )
on conflict do nothing;


-- ============================================================
-- 3. SINCRONIZAR AUTOMATICAMENTE QUANDO O RESPONSÁVEL MUDA
-- ============================================================

create or replace function
  public.sync_colab_roadmap_primary_assignee()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Remove qualquer vínculo antigo deste item.
  delete from
    public.colab_roadmap_assignees
  where
    roadmap_item_id = new.id;

  -- Recria apenas o responsável atual.
  if new.assignee_user_id is not null then
    insert into
      public.colab_roadmap_assignees (
        roadmap_item_id,
        user_id
      )
    values (
      new.id,
      new.assignee_user_id
    )
    on conflict do nothing;
  end if;

  return new;
end;
$$;


drop trigger if exists
  trg_sync_colab_roadmap_primary_assignee
on
  public.colab_roadmap_items;

create trigger
  trg_sync_colab_roadmap_primary_assignee
after insert or update of assignee_user_id
on
  public.colab_roadmap_items
for each row
execute function
  public.sync_colab_roadmap_primary_assignee();


-- ============================================================
-- 4. IMPEDIR QUE CÓDIGO LEGADO REINTRODUZA RESPONSÁVEL ERRADO
-- ============================================================

create or replace function
  public.enforce_colab_roadmap_single_assignee()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_primary_user_id uuid;
begin
  select
    r.assignee_user_id
  into
    v_primary_user_id
  from
    public.colab_roadmap_items r
  where
    r.id = new.roadmap_item_id;

  -- Se não existe item, deixa FK/constraint tratar.
  if not found then
    return new;
  end if;

  -- Sem responsável principal = não existe vínculo válido.
  if v_primary_user_id is null then
    return null;
  end if;

  -- Só o responsável principal pode existir na tabela auxiliar.
  if new.user_id is distinct from v_primary_user_id then
    return null;
  end if;

  return new;
end;
$$;


drop trigger if exists
  trg_enforce_colab_roadmap_single_assignee
on
  public.colab_roadmap_assignees;

create trigger
  trg_enforce_colab_roadmap_single_assignee
before insert or update
on
  public.colab_roadmap_assignees
for each row
execute function
  public.enforce_colab_roadmap_single_assignee();


-- ============================================================
-- 5. NOTIFICAÇÕES ANTIGAS
-- ============================================================
--
-- Uma notificação antiga para alguém que deixou de ser responsável
-- não deve continuar parecendo uma tarefa ativa.
--

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
  r.id = n.roadmap_item_id
  and n.is_read = false
  and r.assignee_user_id
    is distinct from
    n.user_id;


-- ============================================================
-- 6. RPC CANÔNICA PARA "MINHAS TAREFAS"
-- ============================================================
--
-- Mantemos a função existente, mas a origem passa a ser diretamente
-- colab_roadmap_items.assignee_user_id = auth.uid().
--

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
    coalesce(r.progress, 0)::integer,
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
      n.roadmap_item_id = r.id
      and n.user_id = auth.uid()
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
    and r.assignee_user_id = auth.uid()
    and (
      r.status is null
      or r.status <> 'done'
    )
    and (
      r.stage is null
      or r.stage <> 'done'
    )

  order by
    case
      r.stage
      when 'now' then 0
      when 'next' then 1
      when 'later' then 2
      else 3
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


-- ============================================================
-- 7. ÍNDICES
-- ============================================================

create index if not exists
  colab_roadmap_items_assignee_user_id_idx
on
  public.colab_roadmap_items (
    assignee_user_id
  );

create index if not exists
  colab_roadmap_assignees_item_user_idx
on
  public.colab_roadmap_assignees (
    roadmap_item_id,
    user_id
  );


commit;

notify pgrst, 'reload schema';
