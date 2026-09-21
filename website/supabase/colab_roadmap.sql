create extension if not exists pgcrypto;

create table if not exists public.colab_roadmap_items (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 140),
  description text,
  stage text not null default 'now' check (stage in ('now','next','later','done')),
  status text not null default 'todo' check (status in ('todo','in_progress','blocked','done')),
  priority text not null default 'medium' check (priority in ('low','medium','high')),
  area text,
  progress integer not null default 0 check (progress between 0 and 100),
  assignee_user_id uuid references auth.users(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete cascade,
  due_date date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists colab_roadmap_items_stage_idx on public.colab_roadmap_items(stage);
create index if not exists colab_roadmap_items_status_idx on public.colab_roadmap_items(status);
create index if not exists colab_roadmap_items_assignee_idx on public.colab_roadmap_items(assignee_user_id);

alter table public.colab_roadmap_items enable row level security;

drop policy if exists "Authenticated collaborators can read roadmap" on public.colab_roadmap_items;
create policy "Authenticated collaborators can read roadmap" on public.colab_roadmap_items for select to authenticated using (auth.uid() is not null);

drop policy if exists "Authenticated collaborators can create roadmap items" on public.colab_roadmap_items;
create policy "Authenticated collaborators can create roadmap items" on public.colab_roadmap_items for insert to authenticated with check (auth.uid() = created_by);

drop policy if exists "Authenticated collaborators can update roadmap items" on public.colab_roadmap_items;
create policy "Authenticated collaborators can update roadmap items" on public.colab_roadmap_items for update to authenticated using (auth.uid() is not null) with check (auth.uid() is not null);

drop policy if exists "Authenticated collaborators can delete roadmap items" on public.colab_roadmap_items;
create policy "Authenticated collaborators can delete roadmap items" on public.colab_roadmap_items for delete to authenticated using (auth.uid() is not null);

grant select, insert, update, delete on public.colab_roadmap_items to authenticated;
