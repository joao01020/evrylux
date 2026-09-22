-- ============================================================
-- EVRYLUX — PRESENÇA ONLINE COMPARTILHADA
-- ============================================================
--
-- Corrige o caso em que cada navegador enxerga somente a própria
-- presença. Em vez de depender apenas do Presence efêmero do canal,
-- cada sessão envia um heartbeat ao banco.
--
-- Vantagens:
-- - todos os colaboradores autenticados enxergam a mesma lista;
-- - suporta múltiplas abas/dispositivos por usuário;
-- - sessões antigas expiram automaticamente;
-- - nenhuma alteração necessária no Dashboard.
--
-- ============================================================

begin;

create table if not exists public.colab_presence_sessions (
  session_id text primary key,

  user_id uuid not null
    references auth.users(id)
    on delete cascade,

  display_name text not null,

  avatar_url text,

  area text,

  github_login text,

  last_seen_at timestamptz not null
    default now(),

  created_at timestamptz not null
    default now()
);

create index if not exists
  colab_presence_sessions_user_idx
on public.colab_presence_sessions (
  user_id,
  last_seen_at desc
);

create index if not exists
  colab_presence_sessions_seen_idx
on public.colab_presence_sessions (
  last_seen_at desc
);

alter table public.colab_presence_sessions
  enable row level security;

revoke all
on table public.colab_presence_sessions
from public, anon, authenticated;

-- ============================================================
-- HEARTBEAT DA SESSÃO ATUAL
-- ============================================================

drop function if exists
  public.upsert_colab_presence_session(
    text,
    text,
    text,
    text,
    text
  );

create function public.upsert_colab_presence_session(
  p_session_id text,
  p_display_name text,
  p_avatar_url text default null,
  p_area text default null,
  p_github_login text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception
      'Sessão autenticada necessária'
      using errcode = '42501';
  end if;

  if char_length(
    trim(
      coalesce(
        p_session_id,
        ''
      )
    )
  ) < 8 then
    raise exception
      'Identificador de presença inválido';
  end if;

  -- Limpeza leve de sessões antigas.
  delete from public.colab_presence_sessions
  where
    last_seen_at <
      now() - interval '5 minutes';

  insert into public.colab_presence_sessions (
    session_id,
    user_id,
    display_name,
    avatar_url,
    area,
    github_login,
    last_seen_at
  )
  values (
    trim(p_session_id),
    auth.uid(),
    coalesce(
      nullif(
        trim(
          coalesce(
            p_display_name,
            ''
          )
        ),
        ''
      ),
      'Colaborador EVRYLUX'
    ),
    nullif(
      trim(
        coalesce(
          p_avatar_url,
          ''
        )
      ),
      ''
    ),
    nullif(
      trim(
        coalesce(
          p_area,
          ''
        )
      ),
      ''
    ),
    nullif(
      trim(
        coalesce(
          p_github_login,
          ''
        )
      ),
      ''
    ),
    now()
  )
  on conflict (
    session_id
  )
  do update set
    user_id =
      auth.uid(),

    display_name =
      excluded.display_name,

    avatar_url =
      excluded.avatar_url,

    area =
      excluded.area,

    github_login =
      excluded.github_login,

    last_seen_at =
      now();

  return true;
end;
$$;

-- ============================================================
-- LISTAR USUÁRIOS REALMENTE ONLINE
-- ============================================================
--
-- Uma sessão é considerada online por 45 segundos após o último
-- heartbeat. Como o navegador atualiza a cada 15s, existe margem
-- para pequenas pausas de rede.
--
-- Se o mesmo usuário estiver em mais de uma aba, ele aparece uma
-- única vez.
--
-- ============================================================

drop function if exists
  public.list_active_colab_presence();

create function public.list_active_colab_presence()
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  area text,
  github_login text,
  online_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select distinct on (
    p.user_id
  )
    p.user_id,
    p.display_name,
    p.avatar_url,
    p.area,
    p.github_login,
    p.last_seen_at as online_at
  from public.colab_presence_sessions p
  where
    auth.uid() is not null
    and p.last_seen_at >=
      now() - interval '45 seconds'
  order by
    p.user_id,
    p.last_seen_at desc;
$$;

-- ============================================================
-- ENCERRAR UMA SESSÃO
-- ============================================================

drop function if exists
  public.remove_colab_presence_session(text);

create function public.remove_colab_presence_session(
  p_session_id text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return false;
  end if;

  delete from public.colab_presence_sessions
  where
    session_id =
      p_session_id
    and user_id =
      auth.uid();

  return found;
end;
$$;

revoke all
on function public.upsert_colab_presence_session(
  text,
  text,
  text,
  text,
  text
)
from public, anon;

revoke all
on function public.list_active_colab_presence()
from public, anon;

revoke all
on function public.remove_colab_presence_session(text)
from public, anon;

grant execute
on function public.upsert_colab_presence_session(
  text,
  text,
  text,
  text,
  text
)
to authenticated;

grant execute
on function public.list_active_colab_presence()
to authenticated;

grant execute
on function public.remove_colab_presence_session(text)
to authenticated;

commit;

notify pgrst, 'reload schema';
