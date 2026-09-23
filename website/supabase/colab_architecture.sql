begin;

create extension if not exists pgcrypto;

create table if not exists public.colab_architecture_nodes (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  title text not null,
  subtitle text,
  summary text,
  description text,
  category text not null default 'architecture',
  responsibilities text[] not null default '{}'::text[],
  technologies text[] not null default '{}'::text[],
  files text[] not null default '{}'::text[],
  database_objects text[] not null default '{}'::text[],
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table
  public.colab_architecture_nodes
add column if not exists
  summary text;

create table if not exists public.colab_architecture_history (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  category text not null default 'architecture',
  components text[] not null default '{}'::text[],
  files text[] not null default '{}'::text[],
  database_objects text[] not null default '{}'::text[],
  source_url text,
  occurred_at date not null default current_date,
  created_by uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create index if not exists colab_architecture_history_occurred_idx
on public.colab_architecture_history (occurred_at desc, created_at desc);

alter table public.colab_architecture_nodes enable row level security;
alter table public.colab_architecture_history enable row level security;

revoke all on table public.colab_architecture_nodes from public, anon, authenticated;
revoke all on table public.colab_architecture_history from public, anon, authenticated;

insert into public.colab_architecture_nodes (
  slug,
  title,
  subtitle,
  summary,
  description,
  category,
  responsibilities,
  technologies,
  files,
  database_objects,
  sort_order
)
values
(
  'flutter',
  'Flutter',
  'Aplicativo principal',
  'Interface · módulos · estado local',
  'Frontend principal do EVRYLUX. Reúne interface, módulos do produto, estado local e integração com os serviços remotos.',
  'frontend',
  array['Interface do usuário','Cérebro','Finanças','Treino','Rotina','Estado local','Experiência desktop'],
  array['Flutter','Dart'],
  array['app/lib/','app/assets/'],
  array[]::text[],
  10
),
(
  'supabase',
  'Supabase',
  'Backend e serviços',
  'RPCs · Realtime · infraestrutura',
  'Camada remota usada pelo EVRYLUX para banco, autenticação, RPCs, Realtime, Storage e sincronização.',
  'backend',
  array['Banco remoto','RPCs','Realtime','Storage','Autenticação','Integração com o aplicativo e portal'],
  array['Supabase','PostgreSQL'],
  array['website/src/lib/supabase.ts','supabase/migrations/'],
  array['RPCs públicas controladas','RLS'],
  20
),
(
  'postgresql',
  'PostgreSQL',
  'Dados persistidos',
  'Tabelas · RLS · RPCs',
  'Banco relacional que mantém estruturas sincronizadas, perfis, dados do portal e demais entidades persistentes.',
  'database',
  array['Persistência','Integridade relacional','Policies','Funções e RPCs'],
  array['PostgreSQL'],
  array['supabase/migrations/','website/supabase/'],
  array['brain_concepts','brain_notes','brain_reviews','brain_objects','member_profiles'],
  30
),
(
  'storage',
  'Storage',
  'Arquivos',
  'Anexos · avatares · objetos',
  'Armazenamento de objetos usado para arquivos associados ao projeto, avatares e outros conteúdos fora das tabelas relacionais.',
  'backend',
  array['Arquivos','Avatares','Anexos','Objetos privados'],
  array['Supabase Storage'],
  array['website/src/lib/'],
  array['storage.buckets','storage.objects'],
  40
),
(
  'auth',
  'Auth / RLS',
  'Identidade e autorização',
  'Sessão · políticas · AAL2',
  'Camada responsável por sessão, autenticação, controle de acesso, políticas por usuário e proteção de operações administrativas.',
  'security',
  array['Sessão','Autenticação','RLS','Permissões','AAL2 / 2FA'],
  array['Supabase Auth','PostgreSQL RLS','TOTP'],
  array['website/src/lib/member-auth.ts','website/src/lib/mfa.ts','website/src/lib/colab-admin.ts'],
  array['auth.users','colab_user_roles'],
  50
),
(
  'sync',
  'Sync',
  'Offline e convergência',
  'Offline · dispositivos · conflitos',
  'Responsável por reconciliar dados locais e remotos, preservar operações offline e manter convergência entre dispositivos.',
  'sync',
  array['Offline-first','Sincronização','Convergência','Tombstones','Dispositivos'],
  array['Flutter','Supabase','Persistência local'],
  array['app/lib/study/brain/','app/lib/core/'],
  array['brain_objects','brain_devices'],
  60
),
(
  'vault',
  'Vault / E2EE',
  'Segurança local',
  'Chaves · envelopes · dispositivos',
  'Direção de segurança para proteger dados sensíveis, chaves e sincronização entre dispositivos autorizados.',
  'security',
  array['Criptografia ponta a ponta','Proteção de chaves','Dispositivos autorizados','Envelopes de chave'],
  array['E2EE','Vault local'],
  array['app/lib/study/brain/'],
  array['brain_devices','brain_device_key_envelopes'],
  70
)
on conflict (slug)
do nothing;

drop function if exists public.list_colab_architecture_nodes();

create function public.list_colab_architecture_nodes()
returns table (
  id uuid,
  slug text,
  title text,
  subtitle text,
  summary text,
  description text,
  category text,
  responsibilities text[],
  technologies text[],
  files text[],
  database_objects text[],
  sort_order integer,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    n.id,
    n.slug,
    n.title,
    n.subtitle,
    n.summary,
    n.description,
    n.category,
    n.responsibilities,
    n.technologies,
    n.files,
    n.database_objects,
    n.sort_order,
    n.created_at,
    n.updated_at
  from public.colab_architecture_nodes n
  where auth.uid() is not null
  order by n.sort_order, n.title;
$$;

drop function if exists public.list_colab_architecture_history();

create function public.list_colab_architecture_history()
returns table (
  id uuid,
  title text,
  description text,
  category text,
  components text[],
  files text[],
  database_objects text[],
  source_url text,
  occurred_at date,
  created_by uuid,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    h.id,
    h.title,
    h.description,
    h.category,
    h.components,
    h.files,
    h.database_objects,
    h.source_url,
    h.occurred_at,
    h.created_by,
    h.created_at
  from public.colab_architecture_history h
  where auth.uid() is not null
  order by h.occurred_at desc, h.created_at desc;
$$;

drop function if exists public.add_colab_architecture_history_entry(
  text,
  text,
  text,
  text[],
  text[],
  text[],
  text,
  date
);

create function public.add_colab_architecture_history_entry(
  p_title text,
  p_description text,
  p_category text,
  p_components text[],
  p_files text[],
  p_database_objects text[],
  p_source_url text,
  p_occurred_at date
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_allowed_categories constant text[] :=
    array[
      'architecture',
      'database',
      'security',
      'sync',
      'frontend',
      'backend',
      'infrastructure',
      'migration',
      'decision',
      'deprecation'
    ];
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  if char_length(trim(coalesce(p_title,''))) < 3 then
    raise exception 'Título inválido';
  end if;

  if char_length(trim(coalesce(p_description,''))) < 5 then
    raise exception 'Descrição inválida';
  end if;

  if not (
    coalesce(p_category,'architecture') =
    any(v_allowed_categories)
  ) then
    raise exception 'Categoria inválida';
  end if;

  insert into public.colab_architecture_history (
    title,
    description,
    category,
    components,
    files,
    database_objects,
    source_url,
    occurred_at,
    created_by
  )
  values (
    trim(p_title),
    trim(p_description),
    coalesce(p_category,'architecture'),
    coalesce(p_components,'{}'::text[]),
    coalesce(p_files,'{}'::text[]),
    coalesce(p_database_objects,'{}'::text[]),
    nullif(trim(coalesce(p_source_url,'')),''),
    coalesce(p_occurred_at,current_date),
    auth.uid()
  )
  returning id into v_id;

  return v_id;
end;
$$;


drop function if exists public.update_colab_architecture_node(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text[],
  text[],
  text[],
  text[]
);

create function public.update_colab_architecture_node(
  p_node_id uuid,
  p_title text,
  p_subtitle text,
  p_summary text,
  p_description text,
  p_category text,
  p_responsibilities text[],
  p_technologies text[],
  p_files text[],
  p_database_objects text[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_allowed_categories constant text[] :=
    array[
      'architecture',
      'database',
      'security',
      'sync',
      'frontend',
      'backend',
      'infrastructure',
      'migration',
      'decision',
      'deprecation'
    ];
begin
  if auth.uid() is null then
    raise exception 'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  if char_length(trim(coalesce(p_title,''))) < 2 then
    raise exception 'Nome do componente inválido';
  end if;

  if not (
    coalesce(p_category,'architecture') =
    any(v_allowed_categories)
  ) then
    raise exception 'Categoria inválida';
  end if;

  update public.colab_architecture_nodes
  set
    title = trim(p_title),
    subtitle = nullif(trim(coalesce(p_subtitle,'')),''),
    summary = nullif(trim(coalesce(p_summary,'')),''),
    description = nullif(trim(coalesce(p_description,'')),''),
    category = coalesce(p_category,'architecture'),
    responsibilities = coalesce(p_responsibilities,'{}'::text[]),
    technologies = coalesce(p_technologies,'{}'::text[]),
    files = coalesce(p_files,'{}'::text[]),
    database_objects = coalesce(p_database_objects,'{}'::text[]),
    updated_at = now()
  where id = p_node_id
  returning id into v_id;

  if v_id is null then
    raise exception 'Componente não encontrado';
  end if;

  return v_id;
end;
$$;

grant execute on function public.list_colab_architecture_nodes()
to authenticated;

grant execute on function public.list_colab_architecture_history()
to authenticated;

grant execute on function public.update_colab_architecture_node(
  uuid,
  text,
  text,
  text,
  text,
  text,
  text[],
  text[],
  text[],
  text[]
)
to authenticated;


grant execute on function public.add_colab_architecture_history_entry(
  text,
  text,
  text,
  text[],
  text[],
  text[],
  text,
  date
)
to authenticated;

commit;
