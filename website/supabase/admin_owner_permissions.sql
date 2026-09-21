-- ============================================================
-- EVRYLUX COLAB
-- OWNER + ADMINISTRADORES COM PERMISSÕES GRANULARES
--
-- Compatível com a tabela existente public.colab_user_roles.
--
-- Ideia:
--   - colab_user_roles continua dizendo quem é "admin"
--   - apenas UM admin pode ser owner
--   - owner possui todas as permissões
--   - outros admins só possuem permissões concedidas manualmente
--   - AAL2 continua separado da autorização
-- ============================================================

begin;

-- ============================================================
-- COMPATIBILIDADE COM VERSÕES ANTERIORES
-- ============================================================
--
-- PostgreSQL não permite alterar o tipo de retorno de uma função
-- existente usando CREATE OR REPLACE. Como este projeto já teve
-- versões anteriores destas RPCs, removemos as assinaturas antigas
-- antes de recriá-las.
--
-- IMPORTANTE:
-- - isto remove SOMENTE as funções/RPCs abaixo;
-- - não apaga usuários;
-- - não apaga colab_user_roles;
-- - não apaga member_profiles;
-- - não apaga as tabelas de permissões/auditoria.
--
drop function if exists public.list_colab_admins();
drop function if exists public.add_colab_admin_by_email(text);
drop function if exists public.set_colab_admin_permissions(uuid, text[]);
drop function if exists public.remove_colab_admin(uuid);
drop function if exists public.list_colab_admin_audit(integer);
drop function if exists public.claim_colab_owner();
drop function if exists public.is_colab_owner();
drop function if exists public.has_colab_admin_permission(text);
drop function if exists public.is_colab_admin_role();
drop function if exists public.colab_valid_admin_permissions();


-- ------------------------------------------------------------
-- 1. PERFIL ADMINISTRATIVO
-- ------------------------------------------------------------

create table if not exists public.colab_admin_access (
  user_id uuid primary key references auth.users(id) on delete cascade,
  is_owner boolean not null default false,
  permissions text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

-- Garante no máximo um owner.
create unique index if not exists colab_admin_access_single_owner_idx
  on public.colab_admin_access ((is_owner))
  where is_owner = true;

-- ------------------------------------------------------------
-- 2. AUDITORIA
-- ------------------------------------------------------------

create table if not exists public.colab_admin_audit_log (
  id bigint generated always as identity primary key,
  actor_user_id uuid references auth.users(id) on delete set null,
  target_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists colab_admin_audit_log_created_idx
  on public.colab_admin_audit_log (created_at desc);

-- ------------------------------------------------------------
-- 3. PERMISSÕES ACEITAS
-- ------------------------------------------------------------

create or replace function public.colab_valid_admin_permissions()
returns text[]
language sql
immutable
as $$
  select array[
    'view_demo',
    'manage_demo',
    'view_support',
    'reply_support',
    'edit_roadmap',
    'manage_admins',
    'view_audit_logs',
    'manage_notifications',
    'manage_site_content',
    'manage_security'
  ]::text[];
$$;

-- ------------------------------------------------------------
-- 4. HELPERS
-- ------------------------------------------------------------

create or replace function public.is_colab_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.colab_admin_access a
    where a.user_id = auth.uid()
      and a.is_owner = true
  );
$$;

create or replace function public.has_colab_admin_permission(permission_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  access_row public.colab_admin_access%rowtype;
begin
  if auth.uid() is null then
    return false;
  end if;

  select *
  into access_row
  from public.colab_admin_access
  where user_id = auth.uid();

  if not found then
    return false;
  end if;

  if access_row.is_owner then
    return true;
  end if;

  return permission_name = any(access_row.permissions);
end;
$$;

create or replace function public.is_colab_admin_role()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.colab_user_roles r
    where r.user_id = auth.uid()
      and r.role = 'admin'
  );
$$;

-- ------------------------------------------------------------
-- 5. CLAIM INICIAL DO OWNER
--
-- Só funciona se:
--   - ainda NÃO existe owner
--   - usuário atual já é admin em colab_user_roles
--
-- Assim não precisamos colocar e-mail ou UUID dentro da migration.
-- ------------------------------------------------------------

create or replace function public.claim_colab_owner()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária';
  end if;

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
    jsonb_build_object('source', 'claim_colab_owner')
  );

  return true;
end;
$$;

-- ------------------------------------------------------------
-- 6. LISTAR ADMINISTRADORES
-- ------------------------------------------------------------
--
-- PostgreSQL não permite CREATE OR REPLACE quando o tipo de retorno
-- (incluindo OUT parameters / RETURNS TABLE) mudou em relação a uma
-- versão anterior. Removemos somente esta RPC antes de recriá-la.
--
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
  if not (
    public.is_colab_owner()
    or public.has_colab_admin_permission('manage_admins')
  ) then
    raise exception 'Sem permissão para visualizar administradores';
  end if;

  return query
  select
    u.id,
    u.email::text,
    coalesce(mp.display_name, split_part(u.email, '@', 1))::text,
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
    lower(coalesce(mp.display_name, u.email));
end;
$$;

-- ------------------------------------------------------------
-- 7. ADICIONAR ADMIN POR E-MAIL
-- ------------------------------------------------------------

create or replace function public.add_colab_admin_by_email(target_email text)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  target_id uuid;
begin
  if not (
    public.is_colab_owner()
    or public.has_colab_admin_permission('manage_admins')
  ) then
    raise exception 'Sem permissão para adicionar administradores';
  end if;

  select id
  into target_id
  from auth.users
  where lower(email) = lower(trim(target_email))
  limit 1;

  if target_id is null then
    raise exception 'Nenhum usuário encontrado com esse e-mail';
  end if;

  insert into public.colab_user_roles (user_id, role)
  values (target_id, 'admin')
  on conflict (user_id)
  do update set role = 'admin';

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
    jsonb_build_object('email', lower(trim(target_email)))
  );

  return target_id;
end;
$$;

-- ------------------------------------------------------------
-- 8. ATUALIZAR PERMISSÕES
--
-- Somente OWNER pode alterar permissões.
-- Isso evita que um admin aumente os próprios poderes.
-- ------------------------------------------------------------

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
  if not public.is_colab_owner() then
    raise exception 'Somente o proprietário pode alterar permissões';
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
  from unnest(coalesce(new_permissions, '{}'::text[])) p
  where not (p = any(public.colab_valid_admin_permissions()))
  limit 1;

  if invalid_permission is not null then
    raise exception 'Permissão inválida: %', invalid_permission;
  end if;

  select coalesce(array_agg(distinct p order by p), '{}'::text[])
  into normalized
  from unnest(coalesce(new_permissions, '{}'::text[])) p;

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
    jsonb_build_object('permissions', normalized)
  );

  return true;
end;
$$;

-- ------------------------------------------------------------
-- 9. REMOVER ADMIN
-- ------------------------------------------------------------

create or replace function public.remove_colab_admin(target_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if not (
    public.is_colab_owner()
    or public.has_colab_admin_permission('manage_admins')
  ) then
    raise exception 'Sem permissão para remover administradores';
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
    action
  )
  values (
    auth.uid(),
    target_user_id,
    'admin_removed'
  );

  return true;
end;
$$;

-- ------------------------------------------------------------
-- 10. AUDITORIA
-- ------------------------------------------------------------
--
-- Mesmo cuidado para instalações que já tinham uma versão anterior
-- desta RPC com outra estrutura de retorno.
--
create function public.list_colab_admin_audit(limit_rows integer default 50)
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
  if not (
    public.is_colab_owner()
    or public.has_colab_admin_permission('view_audit_logs')
  ) then
    raise exception 'Sem permissão para visualizar auditoria';
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
  left join auth.users au on au.id = l.actor_user_id
  left join auth.users tu on tu.id = l.target_user_id
  order by l.created_at desc
  limit greatest(1, least(coalesce(limit_rows, 50), 200));
end;
$$;

-- ------------------------------------------------------------
-- 11. RLS
-- ------------------------------------------------------------

alter table public.colab_admin_access enable row level security;
alter table public.colab_admin_audit_log enable row level security;

-- Não expomos leitura/escrita direta dessas tabelas ao navegador.
-- O acesso ocorre por RPCs SECURITY DEFINER acima.
drop policy if exists "deny direct colab admin access" on public.colab_admin_access;
create policy "deny direct colab admin access"
on public.colab_admin_access
for all
to authenticated
using (false)
with check (false);

drop policy if exists "deny direct colab audit access" on public.colab_admin_audit_log;
create policy "deny direct colab audit access"
on public.colab_admin_audit_log
for all
to authenticated
using (false)
with check (false);

-- ------------------------------------------------------------
-- 12. GRANTS
-- ------------------------------------------------------------

revoke all on public.colab_admin_access from anon, authenticated;
revoke all on public.colab_admin_audit_log from anon, authenticated;

grant execute on function public.colab_valid_admin_permissions() to authenticated;
grant execute on function public.is_colab_owner() to authenticated;
grant execute on function public.has_colab_admin_permission(text) to authenticated;
grant execute on function public.is_colab_admin_role() to authenticated;
grant execute on function public.claim_colab_owner() to authenticated;
grant execute on function public.list_colab_admins() to authenticated;
grant execute on function public.add_colab_admin_by_email(text) to authenticated;
grant execute on function public.set_colab_admin_permissions(uuid, text[]) to authenticated;
grant execute on function public.remove_colab_admin(uuid) to authenticated;
grant execute on function public.list_colab_admin_audit(integer) to authenticated;

commit;
