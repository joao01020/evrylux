-- ============================================================
-- EVRYLUX — SECURITY HARDENING
-- Segurança real no Supabase/PostgreSQL
--
-- Objetivos:
--   1. manter autorização no banco, nunca no frontend;
--   2. exigir sessão autenticada;
--   3. exigir AAL2 em operações administrativas sensíveis;
--   4. reduzir exposição de tabelas administrativas;
--   5. preservar auditoria;
--   6. restringir EXECUTE de RPCs.
--
-- IMPORTANTE:
-- Rate limit de LOGIN do Supabase Auth NÃO é configurado por SQL.
-- Ele deve ser configurado em:
-- Supabase Dashboard -> Authentication -> Rate Limits
-- ============================================================

begin;

-- ============================================================
-- 1. HELPERS DE SESSÃO / MFA
-- ============================================================

create or replace function public.evrylux_current_aal()
returns text
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce(
    auth.jwt() ->> 'aal',
    'aal1'
  );
$$;

create or replace function public.evrylux_is_aal2()
returns boolean
language sql
stable
security invoker
set search_path = public
as $$
  select
    auth.uid() is not null
    and public.evrylux_current_aal() = 'aal2';
$$;

create or replace function public.evrylux_require_authenticated()
returns void
language plpgsql
stable
security invoker
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;
end;
$$;

create or replace function public.evrylux_require_aal2()
returns void
language plpgsql
stable
security invoker
set search_path = public
as $$
begin
  perform public.evrylux_require_authenticated();

  if not public.evrylux_is_aal2() then
    raise exception 'Autenticação reforçada (AAL2) necessária'
      using errcode = '42501';
  end if;
end;
$$;

-- Não permitir chamada anônima desses helpers.
revoke all on function public.evrylux_current_aal() from public, anon;
revoke all on function public.evrylux_is_aal2() from public, anon;
revoke all on function public.evrylux_require_authenticated() from public, anon;
revoke all on function public.evrylux_require_aal2() from public, anon;

grant execute on function public.evrylux_current_aal() to authenticated;
grant execute on function public.evrylux_is_aal2() to authenticated;
grant execute on function public.evrylux_require_authenticated() to authenticated;
grant execute on function public.evrylux_require_aal2() to authenticated;

-- ============================================================
-- 2. TABELAS ADMINISTRATIVAS
-- ============================================================
-- Estas tabelas já fazem parte da arquitetura atual do EVRYLUX.
-- Mantemos RLS e bloqueamos acesso direto pelo navegador.
-- As operações devem acontecer por RPCs validadas.

alter table if exists public.colab_admin_access
  enable row level security;

alter table if exists public.colab_admin_audit_log
  enable row level security;

revoke all on table public.colab_admin_access
  from public, anon, authenticated;

revoke all on table public.colab_admin_audit_log
  from public, anon, authenticated;

drop policy if exists "deny direct colab admin access"
  on public.colab_admin_access;

create policy "deny direct colab admin access"
on public.colab_admin_access
for all
to authenticated
using (false)
with check (false);

drop policy if exists "deny direct colab audit access"
  on public.colab_admin_audit_log;

create policy "deny direct colab audit access"
on public.colab_admin_audit_log
for all
to authenticated
using (false)
with check (false);

-- ============================================================
-- 3. RESTRINGIR EXECUTE DE RPCs ADMINISTRATIVAS
-- ============================================================

revoke all on function public.is_colab_owner()
  from public, anon;

revoke all on function public.has_colab_admin_permission(text)
  from public, anon;

revoke all on function public.is_colab_admin_role()
  from public, anon;

revoke all on function public.claim_colab_owner()
  from public, anon;

revoke all on function public.list_colab_admins()
  from public, anon;

revoke all on function public.add_colab_admin_by_email(text)
  from public, anon;

revoke all on function public.set_colab_admin_permissions(uuid, text[])
  from public, anon;

revoke all on function public.remove_colab_admin(uuid)
  from public, anon;

revoke all on function public.list_colab_admin_audit(integer)
  from public, anon;

grant execute on function public.is_colab_owner()
  to authenticated;

grant execute on function public.has_colab_admin_permission(text)
  to authenticated;

grant execute on function public.is_colab_admin_role()
  to authenticated;

grant execute on function public.claim_colab_owner()
  to authenticated;

grant execute on function public.list_colab_admins()
  to authenticated;

grant execute on function public.add_colab_admin_by_email(text)
  to authenticated;

grant execute on function public.set_colab_admin_permissions(uuid, text[])
  to authenticated;

grant execute on function public.remove_colab_admin(uuid)
  to authenticated;

grant execute on function public.list_colab_admin_audit(integer)
  to authenticated;

-- ============================================================
-- 4. CLAIM DO OWNER — EXIGE AAL2
-- ============================================================

create or replace function public.claim_colab_owner()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.evrylux_require_aal2();

  if exists (
    select 1
    from public.colab_admin_access
    where is_owner = true
  ) then
    raise exception 'O proprietário do EVRYLUX Colab já foi definido';
  end if;

  if not exists (
    select 1
    from public.colab_user_roles
    where user_id = auth.uid()
      and role = 'admin'
  ) then
    raise exception 'A conta precisa já possuir papel admin';
  end if;

  insert into public.colab_admin_access (
    user_id,
    is_owner,
    permissions,
    updated_by
  )
  values (
    auth.uid(),
    true,
    public.colab_valid_admin_permissions(),
    auth.uid()
  )
  on conflict (user_id)
  do update set
    is_owner = true,
    permissions = public.colab_valid_admin_permissions(),
    updated_at = now(),
    updated_by = auth.uid();

  insert into public.colab_admin_audit_log (
    actor_user_id,
    target_user_id,
    action,
    details
  )
  values (
    auth.uid(),
    auth.uid(),
    'owner_claimed',
    jsonb_build_object(
      'source', 'claim_colab_owner',
      'aal', public.evrylux_current_aal()
    )
  );

  return true;
end;
$$;

-- ============================================================
-- 5. ADICIONAR ADMIN — EXIGE AAL2 + PERMISSÃO
-- ============================================================

create or replace function public.add_colab_admin_by_email(
  target_email text
)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  target_id uuid;
begin
  perform public.evrylux_require_aal2();

  if not (
    public.is_colab_owner()
    or public.has_colab_admin_permission('manage_admins')
  ) then
    raise exception 'Sem permissão para adicionar administradores'
      using errcode = '42501';
  end if;

  if target_email is null
     or length(trim(target_email)) < 3
     or length(trim(target_email)) > 254 then
    raise exception 'E-mail inválido';
  end if;

  select id
  into target_id
  from auth.users
  where lower(email) = lower(trim(target_email))
  limit 1;

  if target_id is null then
    -- Não exponha esta mensagem em uma página pública.
    -- Esta RPC é apenas para área administrativa AAL2.
    raise exception 'Usuário não encontrado';
  end if;

  insert into public.colab_user_roles (
    user_id,
    role
  )
  values (
    target_id,
    'admin'
  )
  on conflict (user_id)
  do update set
    role = 'admin';

  insert into public.colab_admin_access (
    user_id,
    is_owner,
    permissions,
    updated_by
  )
  values (
    target_id,
    false,
    '{}',
    auth.uid()
  )
  on conflict (user_id)
  do nothing;

  insert into public.colab_admin_audit_log (
    actor_user_id,
    target_user_id,
    action,
    details
  )
  values (
    auth.uid(),
    target_id,
    'admin_added',
    jsonb_build_object(
      'aal', public.evrylux_current_aal()
    )
  );

  return target_id;
end;
$$;

-- ============================================================
-- 6. ALTERAR PERMISSÕES — OWNER + AAL2
-- ============================================================

create or replace function public.set_colab_admin_permissions(
  target_user_id uuid,
  new_permissions text[]
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  invalid_permission text;
  normalized text[];
begin
  perform public.evrylux_require_aal2();

  if not public.is_colab_owner() then
    raise exception 'Somente o proprietário pode alterar permissões'
      using errcode = '42501';
  end if;

  if target_user_id is null then
    raise exception 'Usuário inválido';
  end if;

  if target_user_id = auth.uid() then
    raise exception 'As permissões do proprietário são sempre totais';
  end if;

  if exists (
    select 1
    from public.colab_admin_access
    where user_id = target_user_id
      and is_owner = true
  ) then
    raise exception 'O proprietário não pode ter permissões reduzidas';
  end if;

  if not exists (
    select 1
    from public.colab_user_roles
    where user_id = target_user_id
      and role = 'admin'
  ) then
    raise exception 'O usuário não é administrador';
  end if;

  select p
  into invalid_permission
  from unnest(
    coalesce(
      new_permissions,
      '{}'::text[]
    )
  ) p
  where not (
    p = any(
      public.colab_valid_admin_permissions()
    )
  )
  limit 1;

  if invalid_permission is not null then
    raise exception 'Permissão inválida: %', invalid_permission;
  end if;

  select coalesce(
    array_agg(
      distinct p
      order by p
    ),
    '{}'::text[]
  )
  into normalized
  from unnest(
    coalesce(
      new_permissions,
      '{}'::text[]
    )
  ) p;

  insert into public.colab_admin_access (
    user_id,
    is_owner,
    permissions,
    updated_by
  )
  values (
    target_user_id,
    false,
    normalized,
    auth.uid()
  )
  on conflict (user_id)
  do update set
    permissions = excluded.permissions,
    updated_at = now(),
    updated_by = auth.uid();

  insert into public.colab_admin_audit_log (
    actor_user_id,
    target_user_id,
    action,
    details
  )
  values (
    auth.uid(),
    target_user_id,
    'permissions_updated',
    jsonb_build_object(
      'permissions', normalized,
      'aal', public.evrylux_current_aal()
    )
  );

  return true;
end;
$$;

-- ============================================================
-- 7. REMOVER ADMIN — AAL2 + PERMISSÃO
-- ============================================================

create or replace function public.remove_colab_admin(
  target_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.evrylux_require_aal2();

  if not (
    public.is_colab_owner()
    or public.has_colab_admin_permission('manage_admins')
  ) then
    raise exception 'Sem permissão para remover administradores'
      using errcode = '42501';
  end if;

  if target_user_id is null then
    raise exception 'Usuário inválido';
  end if;

  if target_user_id = auth.uid() then
    raise exception 'Você não pode remover sua própria conta por esta operação';
  end if;

  if exists (
    select 1
    from public.colab_admin_access
    where user_id = target_user_id
      and is_owner = true
  ) then
    raise exception 'O proprietário não pode ser removido';
  end if;

  delete from public.colab_admin_access
  where user_id = target_user_id;

  delete from public.colab_user_roles
  where user_id = target_user_id
    and role = 'admin';

  insert into public.colab_admin_audit_log (
    actor_user_id,
    target_user_id,
    action,
    details
  )
  values (
    auth.uid(),
    target_user_id,
    'admin_removed',
    jsonb_build_object(
      'aal', public.evrylux_current_aal()
    )
  );

  return true;
end;
$$;

-- ============================================================
-- 8. LISTAGEM DE ADMINS — AUTORIZAÇÃO REAL NO BANCO
-- ============================================================
-- Não exigimos AAL2 apenas para leitura da lista,
-- mas exigimos owner ou manage_admins.

drop function if exists public.list_colab_admins();

create function public.list_colab_admins()
returns table (
  user_id uuid,
  email text,
  display_name text,
  avatar_url text,
  is_owner boolean,
  permissions text[],
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, auth
as $$
begin
  perform public.evrylux_require_authenticated();

  if not (
    public.is_colab_owner()
    or public.has_colab_admin_permission('manage_admins')
  ) then
    raise exception 'Sem permissão para visualizar administradores'
      using errcode = '42501';
  end if;

  return query
  select
    u.id,
    u.email::text,
    coalesce(
      mp.display_name,
      split_part(u.email, '@', 1)
    )::text,
    mp.avatar_url::text,
    coalesce(a.is_owner, false),
    coalesce(a.permissions, '{}'::text[]),
    coalesce(a.created_at, u.created_at),
    coalesce(a.updated_at, u.updated_at)
  from public.colab_user_roles r
  join auth.users u
    on u.id = r.user_id
  left join public.member_profiles mp
    on mp.user_id = u.id
  left join public.colab_admin_access a
    on a.user_id = u.id
  where r.role = 'admin'
  order by
    coalesce(a.is_owner, false) desc,
    lower(
      coalesce(
        mp.display_name,
        u.email
      )
    );
end;
$$;

-- ============================================================
-- 9. AUDITORIA — AAL2
-- ============================================================

drop function if exists public.list_colab_admin_audit(integer);

create function public.list_colab_admin_audit(
  limit_rows integer default 50
)
returns table (
  id bigint,
  actor_user_id uuid,
  actor_email text,
  target_user_id uuid,
  target_email text,
  action text,
  details jsonb,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, auth
as $$
begin
  perform public.evrylux_require_aal2();

  if not (
    public.is_colab_owner()
    or public.has_colab_admin_permission('view_audit_logs')
  ) then
    raise exception 'Sem permissão para visualizar auditoria'
      using errcode = '42501';
  end if;

  return query
  select
    l.id,
    l.actor_user_id,
    au.email::text,
    l.target_user_id,
    tu.email::text,
    l.action,
    l.details,
    l.created_at
  from public.colab_admin_audit_log l
  left join auth.users au
    on au.id = l.actor_user_id
  left join auth.users tu
    on tu.id = l.target_user_id
  order by l.created_at desc
  limit greatest(
    1,
    least(
      coalesce(limit_rows, 50),
      200
    )
  );
end;
$$;

-- ============================================================
-- 10. GRANTS FINAIS
-- ============================================================

revoke all on function public.claim_colab_owner()
  from public, anon;

revoke all on function public.add_colab_admin_by_email(text)
  from public, anon;

revoke all on function public.set_colab_admin_permissions(uuid, text[])
  from public, anon;

revoke all on function public.remove_colab_admin(uuid)
  from public, anon;

revoke all on function public.list_colab_admins()
  from public, anon;

revoke all on function public.list_colab_admin_audit(integer)
  from public, anon;

grant execute on function public.claim_colab_owner()
  to authenticated;

grant execute on function public.add_colab_admin_by_email(text)
  to authenticated;

grant execute on function public.set_colab_admin_permissions(uuid, text[])
  to authenticated;

grant execute on function public.remove_colab_admin(uuid)
  to authenticated;

grant execute on function public.list_colab_admins()
  to authenticated;

grant execute on function public.list_colab_admin_audit(integer)
  to authenticated;

commit;

-- ============================================================
-- FIM
-- ============================================================
