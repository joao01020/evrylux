-- ============================================================
-- EVRYLUX — SECURITY AUDIT (somente leitura)
-- Execute no Supabase SQL Editor depois do hardening.
-- ============================================================

-- 1. Tabelas públicas sem RLS.
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n
  on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind = 'r'
  and c.relrowsecurity = false
order by c.relname;

-- 2. Funções SECURITY DEFINER no schema public.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  r.rolname as owner
from pg_proc p
join pg_namespace n
  on n.oid = p.pronamespace
join pg_roles r
  on r.oid = p.proowner
where n.nspname = 'public'
  and p.prosecdef = true
order by p.proname;

-- 3. Grants de tabelas para anon/authenticated.
select
  grantee,
  table_name,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and grantee in ('anon', 'authenticated')
order by table_name, grantee, privilege_type;

-- 4. Políticas RLS existentes.
select
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- 5. Confirmar helpers de AAL.
select
  public.evrylux_current_aal() as current_aal,
  public.evrylux_is_aal2() as is_aal2,
  auth.uid() as current_user_id;

-- 6. Confirmar owner atual (executar autenticado via app/RPC quando aplicável).
-- select public.is_colab_owner();

-- 7. Funções administrativas que devem estar restritas.
select
  routine_name,
  security_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
    'claim_colab_owner',
    'add_colab_admin_by_email',
    'set_colab_admin_permissions',
    'remove_colab_admin',
    'list_colab_admins',
    'list_colab_admin_audit',
    'has_colab_admin_permission',
    'is_colab_owner',
    'is_colab_admin_role'
  )
order by routine_name;
