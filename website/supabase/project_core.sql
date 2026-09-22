-- EVRYLUX — NÚCLEO DO PROJETO
begin;

create or replace function public.colab_valid_admin_permissions()
returns text[]
language sql
immutable
as $$
  select array[
    'view_demo','manage_demo','view_support','reply_support','edit_roadmap',
    'manage_admins','view_audit_logs','manage_notifications','manage_site_content',
    'manage_security','manage_core'
  ]::text[];
$$;

create table if not exists public.project_core_notes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null default '',
  is_pinned boolean not null default false,
  sort_order integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint project_core_notes_title_length check (char_length(title) between 1 and 120),
  constraint project_core_notes_content_length check (char_length(content) <= 8000)
);

create index if not exists project_core_notes_order_idx
  on public.project_core_notes (is_pinned desc, sort_order asc, updated_at desc);

alter table public.project_core_notes enable row level security;
revoke all on table public.project_core_notes from public, anon, authenticated;
drop policy if exists "deny direct core notes access" on public.project_core_notes;
create policy "deny direct core notes access"
on public.project_core_notes for all to authenticated using (false) with check (false);

create or replace function public.can_edit_project_core()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and (
    public.is_colab_owner()
    or (
      public.is_colab_admin_role()
      and public.has_colab_admin_permission('manage_core')
    )
  );
$$;

create or replace function public.require_core_editor()
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária' using errcode = '42501';
  end if;

  if not public.can_edit_project_core() then
    raise exception 'Sem permissão para alterar o Núcleo' using errcode = '42501';
  end if;

  if coalesce(auth.jwt() ->> 'aal', 'aal1') <> 'aal2' then
    raise exception 'Autenticação reforçada (AAL2) necessária' using errcode = '42501';
  end if;
end;
$$;

drop function if exists public.list_project_core_notes();
create function public.list_project_core_notes()
returns table (
  id uuid,
  title text,
  content text,
  is_pinned boolean,
  sort_order integer,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária' using errcode = '42501';
  end if;

  return query
  select n.id,n.title,n.content,n.is_pinned,n.sort_order,n.created_by,n.updated_by,n.created_at,n.updated_at
  from public.project_core_notes n
  order by n.is_pinned desc, n.sort_order asc, n.updated_at desc;
end;
$$;

create or replace function public.create_project_core_note(
  note_title text,
  note_content text default '',
  note_pinned boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
  next_order integer;
begin
  perform public.require_core_editor();
  note_title := trim(coalesce(note_title, ''));
  note_content := coalesce(note_content, '');

  if char_length(note_title) < 1 or char_length(note_title) > 120 then
    raise exception 'O título precisa ter entre 1 e 120 caracteres';
  end if;
  if char_length(note_content) > 8000 then
    raise exception 'O conteúdo pode ter no máximo 8000 caracteres';
  end if;

  select coalesce(max(sort_order), -1) + 1 into next_order from public.project_core_notes;

  insert into public.project_core_notes(title,content,is_pinned,sort_order,created_by,updated_by)
  values(note_title,note_content,coalesce(note_pinned,false),next_order,auth.uid(),auth.uid())
  returning id into new_id;

  insert into public.colab_admin_audit_log(actor_user_id,action,details)
  values(auth.uid(),'core_note_created',jsonb_build_object(
    'note_id',new_id,'title',note_title,'pinned',coalesce(note_pinned,false),
    'aal',coalesce(auth.jwt() ->> 'aal','aal1')
  ));

  return new_id;
end;
$$;

create or replace function public.update_project_core_note(
  note_id uuid,
  note_title text,
  note_content text,
  note_pinned boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_core_editor();
  note_title := trim(coalesce(note_title, ''));
  note_content := coalesce(note_content, '');

  if note_id is null then raise exception 'Nota inválida'; end if;
  if char_length(note_title) < 1 or char_length(note_title) > 120 then
    raise exception 'O título precisa ter entre 1 e 120 caracteres';
  end if;
  if char_length(note_content) > 8000 then
    raise exception 'O conteúdo pode ter no máximo 8000 caracteres';
  end if;

  update public.project_core_notes
  set title=note_title,content=note_content,is_pinned=coalesce(note_pinned,false),
      updated_by=auth.uid(),updated_at=now()
  where id=note_id;

  if not found then raise exception 'Nota não encontrada'; end if;

  insert into public.colab_admin_audit_log(actor_user_id,action,details)
  values(auth.uid(),'core_note_updated',jsonb_build_object(
    'note_id',note_id,'title',note_title,'pinned',coalesce(note_pinned,false),
    'aal',coalesce(auth.jwt() ->> 'aal','aal1')
  ));
  return true;
end;
$$;

create or replace function public.delete_project_core_note(note_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare old_title text;
begin
  perform public.require_core_editor();
  select title into old_title from public.project_core_notes where id=note_id for update;
  if old_title is null then raise exception 'Nota não encontrada'; end if;

  delete from public.project_core_notes where id=note_id;
  insert into public.colab_admin_audit_log(actor_user_id,action,details)
  values(auth.uid(),'core_note_deleted',jsonb_build_object(
    'note_id',note_id,'title',old_title,'aal',coalesce(auth.jwt() ->> 'aal','aal1')
  ));
  return true;
end;
$$;

create or replace function public.set_project_core_editor(
  target_user_id uuid,
  allowed boolean
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  current_permissions text[];
  new_permissions text[];
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária' using errcode = '42501';
  end if;
  if coalesce(auth.jwt() ->> 'aal','aal1') <> 'aal2' then
    raise exception 'Autenticação reforçada (AAL2) necessária' using errcode = '42501';
  end if;
  if not public.is_colab_owner() then
    raise exception 'Somente o proprietário pode alterar esta permissão' using errcode = '42501';
  end if;
  if target_user_id is null then raise exception 'Administrador inválido'; end if;

  if exists(select 1 from public.colab_admin_access where user_id=target_user_id and is_owner=true) then
    return true;
  end if;
  if not exists(select 1 from public.colab_user_roles where user_id=target_user_id and role='admin') then
    raise exception 'O usuário precisa ser administrador';
  end if;

  select coalesce(permissions,'{}'::text[]) into current_permissions
  from public.colab_admin_access where user_id=target_user_id;
  if not found then current_permissions := '{}'::text[]; end if;

  if coalesce(allowed,false) then
    select coalesce(array_agg(distinct p order by p),'{}'::text[])
    into new_permissions
    from unnest(current_permissions || array['manage_core']::text[]) p;
  else
    select coalesce(array_agg(p order by p),'{}'::text[])
    into new_permissions
    from unnest(current_permissions) p where p <> 'manage_core';
  end if;

  insert into public.colab_admin_access(user_id,is_owner,permissions,updated_by)
  values(target_user_id,false,new_permissions,auth.uid())
  on conflict(user_id) do update set
    permissions=excluded.permissions,updated_at=now(),updated_by=auth.uid();

  insert into public.colab_admin_audit_log(actor_user_id,target_user_id,action,details)
  values(auth.uid(),target_user_id,
    case when coalesce(allowed,false) then 'core_editor_granted' else 'core_editor_revoked' end,
    jsonb_build_object('permission','manage_core','allowed',coalesce(allowed,false),
      'aal',coalesce(auth.jwt() ->> 'aal','aal1'))
  );
  return true;
end;
$$;

revoke all on function public.can_edit_project_core() from public, anon;
revoke all on function public.require_core_editor() from public, anon;
revoke all on function public.list_project_core_notes() from public, anon;
revoke all on function public.create_project_core_note(text,text,boolean) from public, anon;
revoke all on function public.update_project_core_note(uuid,text,text,boolean) from public, anon;
revoke all on function public.delete_project_core_note(uuid) from public, anon;
revoke all on function public.set_project_core_editor(uuid,boolean) from public, anon;

grant execute on function public.can_edit_project_core() to authenticated;
grant execute on function public.require_core_editor() to authenticated;
grant execute on function public.list_project_core_notes() to authenticated;
grant execute on function public.create_project_core_note(text,text,boolean) to authenticated;
grant execute on function public.update_project_core_note(uuid,text,text,boolean) to authenticated;
grant execute on function public.delete_project_core_note(uuid) to authenticated;
grant execute on function public.set_project_core_editor(uuid,boolean) to authenticated;

commit;
