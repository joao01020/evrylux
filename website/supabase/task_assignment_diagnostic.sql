-- ============================================================
-- EVRYLUX — DIAGNÓSTICO DE RESPONSÁVEIS
-- Execute DEPOIS da migration principal.
-- Esperado: a primeira consulta deve retornar ZERO linhas.
-- ============================================================

-- 1) Divergências entre responsável principal e tabela auxiliar.
select
  r.id,
  r.title,
  r.assignee_user_id as responsavel_principal,
  a.user_id as responsavel_auxiliar
from
  public.colab_roadmap_items r
left join
  public.colab_roadmap_assignees a
    on a.roadmap_item_id = r.id
where
  (
    r.assignee_user_id is null
    and a.user_id is not null
  )
  or (
    r.assignee_user_id is not null
    and a.user_id is distinct from r.assignee_user_id
  )
order by
  r.title;


-- 2) Estado atual de cada tarefa e responsável.
select
  r.id,
  r.title,
  r.stage,
  r.status,
  r.assignee_user_id,
  p.display_name,
  p.github_login
from
  public.colab_roadmap_items r
left join
  public.member_profiles p
    on p.user_id = r.assignee_user_id
order by
  r.stage,
  r.title;
