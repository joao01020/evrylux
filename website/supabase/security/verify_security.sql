-- ============================================================
-- EVRYLUX — VERIFICAÇÃO PÓS-INSTALAÇÃO
-- ============================================================

-- Deve retornar as funções novas.
select
  proname,
  prosecdef
from pg_proc
where pronamespace = 'public'::regnamespace
  and proname in (
    'evrylux_current_aal',
    'evrylux_is_aal2',
    'evrylux_require_authenticated',
    'evrylux_require_aal2'
  )
order by proname;

-- Deve retornar rls_enabled = true.
select
  relname,
  relrowsecurity as rls_enabled
from pg_class
where relnamespace = 'public'::regnamespace
  and relname in (
    'colab_admin_access',
    'colab_admin_audit_log'
  )
order by relname;

-- Mostra grants atuais das tabelas administrativas.
select
  grantee,
  table_name,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name in (
    'colab_admin_access',
    'colab_admin_audit_log'
  )
order by table_name, grantee, privilege_type;

-- Mostra políticas dessas tabelas.
select
  tablename,
  policyname,
  cmd,
  roles
from pg_policies
where schemaname = 'public'
  and tablename in (
    'colab_admin_access',
    'colab_admin_audit_log'
  )
order by tablename, policyname;
