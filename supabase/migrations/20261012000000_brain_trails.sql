-- Optional normalized index for a future server-side trail path search.
-- V1 desktop stores authoritative trail structures as E2EE generic Vault objects.
-- Do not insert plaintext note titles or trail paths into these tables.
create table if not exists public.brain_trails (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  root_object_id text not null,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_id, root_object_id)
);
create table if not exists public.brain_trail_nodes (
  id uuid primary key default gen_random_uuid(),
  trail_id uuid not null references public.brain_trails(id) on delete cascade,
  object_id text not null,
  parent_node_id uuid references public.brain_trail_nodes(id) on delete cascade,
  position integer not null default 0 check (position >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(trail_id, object_id),
  unique(trail_id, id)
);
create index if not exists brain_trail_nodes_parent_position_idx
  on public.brain_trail_nodes(trail_id, parent_node_id, position);
alter table public.brain_trails enable row level security;
alter table public.brain_trail_nodes enable row level security;
create policy "trail_owner_all" on public.brain_trails
  for all to authenticated using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy "trail_nodes_owner_all" on public.brain_trail_nodes
  for all to authenticated
  using (exists(select 1 from public.brain_trails t where t.id = trail_id and t.owner_id = (select auth.uid())))
  with check (exists(select 1 from public.brain_trails t where t.id = trail_id and t.owner_id = (select auth.uid())));
