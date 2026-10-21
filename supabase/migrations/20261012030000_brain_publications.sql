-- Public snapshots only. NEVER copy source Vault ciphertext/keys into this table.
create table if not exists public.brain_publications (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 title text not null check (length(title) between 1 and 200),
 snapshot jsonb not null,
 allow_import boolean not null default true,
 published boolean not null default true,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists brain_publications_owner_idx on public.brain_publications(owner_id);
alter table public.brain_publications enable row level security;
revoke all on public.brain_publications from anon;
grant select, insert, update, delete on public.brain_publications to authenticated;
drop policy if exists brain_publications_owner on public.brain_publications;
create policy brain_publications_owner on public.brain_publications
 for all to authenticated using (owner_id = (select auth.uid()))
 with check (owner_id = (select auth.uid()));
-- This narrow endpoint only returns explicitly published snapshots by opaque UUID.
create or replace function public.get_brain_publication(publication_id uuid)
returns jsonb language sql stable security definer set search_path = '' as $$
 select jsonb_build_object('id',p.id,'title',p.title,'snapshot',p.snapshot,
   'allow_import',p.allow_import,'updated_at',p.updated_at)
 from public.brain_publications p where p.id=publication_id and p.published=true;
$$;
revoke all on function public.get_brain_publication(uuid) from public;
grant execute on function public.get_brain_publication(uuid) to anon, authenticated;
