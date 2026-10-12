-- ============================================================
-- EVRYLUX / Rotina - abas da lousa
-- ============================================================
-- Mantém nomes, ordem e associação de blocos por aba/dia.
-- Os próprios blocos continuam sendo salvos pelo fluxo existente
-- de routine_days / routine_blocks.
-- ============================================================

create table if not exists public.routine_board_tabs (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  routine_date date not null,
  name text not null,
  sort_order integer not null default 0,
  is_default boolean not null default false,
  block_ids jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint routine_board_tabs_name_not_blank
    check (length(trim(name)) > 0),
  constraint routine_board_tabs_block_ids_array
    check (jsonb_typeof(block_ids) = 'array')
);

create index if not exists routine_board_tabs_user_date_idx
  on public.routine_board_tabs(user_id, routine_date, sort_order);

create unique index if not exists routine_board_tabs_one_default_idx
  on public.routine_board_tabs(user_id, routine_date)
  where is_default = true;

alter table public.routine_board_tabs enable row level security;

create policy "routine_board_tabs_select_own"
  on public.routine_board_tabs
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "routine_board_tabs_insert_own"
  on public.routine_board_tabs
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "routine_board_tabs_update_own"
  on public.routine_board_tabs
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "routine_board_tabs_delete_own"
  on public.routine_board_tabs
  for delete
  to authenticated
  using (auth.uid() = user_id);
