-- ============================================================
-- EVRYLUX — COLABORADORES PÚBLICOS
--
-- A página pública de colaboradores deve usar os perfis salvos
-- no EVRYLUX como fonte principal.
--
-- Esta RPC expõe SOMENTE campos seguros para exibição pública.
-- Nenhum e-mail, role, permissão ou dado administrativo é retornado.
-- ============================================================

begin;

drop function if exists public.list_public_contributors();

create function public.list_public_contributors()
returns table (
  user_id uuid,
  display_name text,
  github_login text,
  bio text,
  avatar_url text,
  area text,
  skills text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    mp.user_id,
    nullif(trim(mp.display_name), '')::text,
    nullif(
      regexp_replace(
        trim(mp.github_login),
        '^@',
        ''
      ),
      ''
    )::text,
    nullif(trim(mp.bio), '')::text,
    nullif(trim(mp.avatar_url), '')::text,
    nullif(trim(mp.area), '')::text,
    nullif(trim(mp.skills), '')::text
  from public.member_profiles mp
  where mp.user_id is not null
  order by
    lower(
      coalesce(
        nullif(trim(mp.display_name), ''),
        nullif(trim(mp.github_login), ''),
        mp.user_id::text
      )
    );
$$;

revoke all on function public.list_public_contributors()
  from public;

grant execute on function public.list_public_contributors()
  to anon, authenticated;

commit;
