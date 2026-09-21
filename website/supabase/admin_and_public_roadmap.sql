-- EVRYLUX
-- Administradores + Roadmap público editável

create extension if not exists pgcrypto;

-- ============================================================
-- 1. PAPÉIS DE USUÁRIO
-- ============================================================

create table if not exists public.colab_user_roles (
  user_id uuid primary key
    references auth.users(id)
    on delete cascade,

  role text not null
    check (
      role in ('admin')
    ),

  created_at timestamptz not null
    default now()
);

alter table public.colab_user_roles
enable row level security;

-- ============================================================
-- 2. FUNÇÃO: É ADMIN?
-- ============================================================

create or replace function public.is_colab_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.colab_user_roles
    where user_id = auth.uid()
      and role = 'admin'
  );
$$;

grant execute
on function public.is_colab_admin()
to anon, authenticated;

-- ============================================================
-- 3. LISTAR ADMINS
-- ============================================================

create or replace function public.list_colab_admins()
returns table (
  user_id uuid,
  email text,
  display_name text,
  github_login text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public, auth
as $$
  select
    r.user_id,
    u.email,
    p.display_name,
    p.github_login,
    r.created_at
  from public.colab_user_roles r
  join auth.users u
    on u.id = r.user_id
  left join public.member_profiles p
    on p.user_id = r.user_id
  where r.role = 'admin'
    and public.is_colab_admin()
  order by r.created_at asc;
$$;

grant execute
on function public.list_colab_admins()
to authenticated;

-- ============================================================
-- 4. ADICIONAR ADMIN POR E-MAIL
-- ============================================================

create or replace function public.add_colab_admin_by_email(
  target_email text
)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  target_id uuid;
begin
  if not public.is_colab_admin() then
    raise exception 'Apenas administradores podem adicionar administradores.';
  end if;

  select id
  into target_id
  from auth.users
  where lower(email) = lower(trim(target_email))
  limit 1;

  if target_id is null then
    raise exception 'Usuário não encontrado em Authentication -> Users.';
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
    role = excluded.role;

  return true;
end;
$$;

grant execute
on function public.add_colab_admin_by_email(text)
to authenticated;

-- ============================================================
-- 5. REMOVER ADMIN
-- ============================================================

create or replace function public.remove_colab_admin(
  target_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  admin_count integer;
begin
  if not public.is_colab_admin() then
    raise exception 'Apenas administradores podem remover administradores.';
  end if;

  if target_user_id = auth.uid() then
    raise exception 'Você não pode remover seu próprio acesso administrativo por esta tela.';
  end if;

  select count(*)
  into admin_count
  from public.colab_user_roles
  where role = 'admin';

  if admin_count <= 1 then
    raise exception 'É necessário manter pelo menos um administrador.';
  end if;

  delete from public.colab_user_roles
  where user_id = target_user_id
    and role = 'admin';

  return true;
end;
$$;

grant execute
on function public.remove_colab_admin(uuid)
to authenticated;

-- ============================================================
-- 6. ROADMAP PÚBLICO
-- ============================================================

create table if not exists public.public_roadmap_items (
  id uuid primary key
    default gen_random_uuid(),

  title text not null
    check (
      char_length(title) between 1 and 140
    ),

  stage text not null
    check (
      stage in (
        'available',
        'development',
        'planned'
      )
    ),

  sort_order integer not null
    default 0,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now()
);

alter table public.public_roadmap_items
enable row level security;

drop policy if exists
  "Public roadmap is readable by everyone"
on public.public_roadmap_items;

create policy
  "Public roadmap is readable by everyone"
on public.public_roadmap_items
for select
to anon, authenticated
using (true);

drop policy if exists
  "Admins can insert public roadmap"
on public.public_roadmap_items;

create policy
  "Admins can insert public roadmap"
on public.public_roadmap_items
for insert
to authenticated
with check (
  public.is_colab_admin()
);

drop policy if exists
  "Admins can update public roadmap"
on public.public_roadmap_items;

create policy
  "Admins can update public roadmap"
on public.public_roadmap_items
for update
to authenticated
using (
  public.is_colab_admin()
)
with check (
  public.is_colab_admin()
);

drop policy if exists
  "Admins can delete public roadmap"
on public.public_roadmap_items;

create policy
  "Admins can delete public roadmap"
on public.public_roadmap_items
for delete
to authenticated
using (
  public.is_colab_admin()
);

grant select
on public.public_roadmap_items
to anon, authenticated;

grant insert, update, delete
on public.public_roadmap_items
to authenticated;

-- ============================================================
-- 7. MIGRAÇÃO INICIAL DO ROADMAP ATUAL
-- Só insere se a tabela estiver vazia.
-- ============================================================

insert into public.public_roadmap_items (
  title,
  stage,
  sort_order
)
select *
from (
  values
    ('Conceitos', 'available', 10),
    ('Perguntas', 'available', 20),
    ('Revisões', 'available', 30),
    ('Busca', 'available', 40),
    ('Estrutura visual do Brain', 'available', 50),

    ('Mapa do conhecimento', 'development', 10),
    ('Sincronização entre dispositivos', 'development', 20),
    ('Fluxos de colaboração', 'development', 30),

    ('Compartilhamento de conhecimento', 'planned', 10),
    ('Recursos de comunidade', 'planned', 20),
    ('Expansão multiplataforma', 'planned', 30)
) as initial_data(
  title,
  stage,
  sort_order
)
where not exists (
  select 1
  from public.public_roadmap_items
);

-- ============================================================
-- 8. PRIMEIRO ADMINISTRADOR
-- IMPORTANTE:
-- Execute DEPOIS deste arquivo, trocando o e-mail:
--
-- insert into public.colab_user_roles (user_id, role)
-- select id, 'admin'
-- from auth.users
-- where lower(email) = lower('SEU_EMAIL_AQUI')
-- on conflict (user_id)
-- do update set role = 'admin';
-- ============================================================
