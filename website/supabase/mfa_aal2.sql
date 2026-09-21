-- ============================================================
-- EVRYLUX COLAB — MFA / AAL2
-- Execute no Supabase SQL Editor
-- ============================================================

create or replace function public.is_aal2_session()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select
    auth.uid() is not null
    and coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2';
$$;

revoke all on function public.is_aal2_session() from public;
grant execute on function public.is_aal2_session() to authenticated;

create or replace function public.has_colab_admin_role()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.colab_user_roles
    where user_id = auth.uid()
      and role = 'admin'
  );
$$;

revoke all on function public.has_colab_admin_role() from public;
grant execute on function public.has_colab_admin_role() to authenticated;

create or replace function public.is_colab_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_aal2_session()
    and exists (
      select 1
      from public.colab_user_roles
      where user_id = auth.uid()
        and role = 'admin'
    );
$$;

revoke all on function public.is_colab_admin() from public;
grant execute on function public.is_colab_admin() to authenticated;

-- ============================================================
-- PROTEÇÕES RESTRICTIVE
-- ============================================================

do $$
begin
  if to_regclass('public.colab_user_roles') is not null then
    execute 'drop policy if exists "mfa_aal2_admin_roles_select" on public.colab_user_roles';
    execute 'drop policy if exists "mfa_aal2_admin_roles_insert" on public.colab_user_roles';
    execute 'drop policy if exists "mfa_aal2_admin_roles_update" on public.colab_user_roles';
    execute 'drop policy if exists "mfa_aal2_admin_roles_delete" on public.colab_user_roles';

    execute $p$
      create policy "mfa_aal2_admin_roles_select"
      on public.colab_user_roles
      as restrictive
      for select
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;

    execute $p$
      create policy "mfa_aal2_admin_roles_insert"
      on public.colab_user_roles
      as restrictive
      for insert
      to authenticated
      with check (public.is_aal2_session())
    $p$;

    execute $p$
      create policy "mfa_aal2_admin_roles_update"
      on public.colab_user_roles
      as restrictive
      for update
      to authenticated
      using (public.is_aal2_session())
      with check (public.is_aal2_session())
    $p$;

    execute $p$
      create policy "mfa_aal2_admin_roles_delete"
      on public.colab_user_roles
      as restrictive
      for delete
      to authenticated
      using (public.is_aal2_session())
    $p$;
  end if;
end
$$;

do $$
begin
  if to_regclass('public.demo_waitlist') is not null then
    execute 'drop policy if exists "mfa_aal2_demo_select" on public.demo_waitlist';
    execute 'drop policy if exists "mfa_aal2_demo_update" on public.demo_waitlist';
    execute 'drop policy if exists "mfa_aal2_demo_delete" on public.demo_waitlist';

    execute $p$
      create policy "mfa_aal2_demo_select"
      on public.demo_waitlist
      as restrictive
      for select
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;

    execute $p$
      create policy "mfa_aal2_demo_update"
      on public.demo_waitlist
      as restrictive
      for update
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
      with check (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;

    execute $p$
      create policy "mfa_aal2_demo_delete"
      on public.demo_waitlist
      as restrictive
      for delete
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;
  end if;
end
$$;

do $$
begin
  if to_regclass('public.support_tickets') is not null then
    execute 'drop policy if exists "mfa_aal2_support_tickets_select" on public.support_tickets';
    execute 'drop policy if exists "mfa_aal2_support_tickets_update" on public.support_tickets';
    execute 'drop policy if exists "mfa_aal2_support_tickets_delete" on public.support_tickets';

    execute $p$
      create policy "mfa_aal2_support_tickets_select"
      on public.support_tickets
      as restrictive
      for select
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;

    execute $p$
      create policy "mfa_aal2_support_tickets_update"
      on public.support_tickets
      as restrictive
      for update
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
      with check (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;

    execute $p$
      create policy "mfa_aal2_support_tickets_delete"
      on public.support_tickets
      as restrictive
      for delete
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;
  end if;
end
$$;

do $$
begin
  if to_regclass('public.support_messages') is not null then
    execute 'drop policy if exists "mfa_aal2_support_messages_select" on public.support_messages';
    execute 'drop policy if exists "mfa_aal2_support_messages_insert" on public.support_messages';
    execute 'drop policy if exists "mfa_aal2_support_messages_update" on public.support_messages';
    execute 'drop policy if exists "mfa_aal2_support_messages_delete" on public.support_messages';

    execute $p$
      create policy "mfa_aal2_support_messages_select"
      on public.support_messages
      as restrictive
      for select
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;

    execute $p$
      create policy "mfa_aal2_support_messages_insert"
      on public.support_messages
      as restrictive
      for insert
      to authenticated
      with check (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;

    execute $p$
      create policy "mfa_aal2_support_messages_update"
      on public.support_messages
      as restrictive
      for update
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
      with check (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;

    execute $p$
      create policy "mfa_aal2_support_messages_delete"
      on public.support_messages
      as restrictive
      for delete
      to authenticated
      using (
        not public.has_colab_admin_role()
        or public.is_aal2_session()
      )
    $p$;
  end if;
end
$$;

-- ============================================================
-- ROADMAP PÚBLICO
-- Protege somente escrita. SELECT público continua como está.
-- ============================================================

do $$
declare
  v_table text;
begin
  foreach v_table in array array[
    'public_roadmap_items',
    'roadmap_public_items',
    'public_roadmap'
  ]
  loop
    if to_regclass('public.' || v_table) is not null then
      execute format(
        'drop policy if exists %I on public.%I',
        'mfa_aal2_' || v_table || '_insert',
        v_table
      );

      execute format(
        'drop policy if exists %I on public.%I',
        'mfa_aal2_' || v_table || '_update',
        v_table
      );

      execute format(
        'drop policy if exists %I on public.%I',
        'mfa_aal2_' || v_table || '_delete',
        v_table
      );

      execute format(
        'create policy %I on public.%I as restrictive for insert to authenticated with check (public.is_aal2_session())',
        'mfa_aal2_' || v_table || '_insert',
        v_table
      );

      execute format(
        'create policy %I on public.%I as restrictive for update to authenticated using (public.is_aal2_session()) with check (public.is_aal2_session())',
        'mfa_aal2_' || v_table || '_update',
        v_table
      );

      execute format(
        'create policy %I on public.%I as restrictive for delete to authenticated using (public.is_aal2_session())',
        'mfa_aal2_' || v_table || '_delete',
        v_table
      );
    end if;
  end loop;
end
$$;

-- No SQL Editor auth.uid() normalmente fica NULL.
-- O teste real de AAL2 acontece pelo app autenticado.
