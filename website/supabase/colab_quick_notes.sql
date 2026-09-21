create extension if not exists pgcrypto;

create table if not exists public.colab_quick_notes (
  id uuid primary key default gen_random_uuid(),

  title text not null
    check (
      char_length(title) between 1 and 120
    ),

  content text not null
    check (
      char_length(content) between 1 and 1600
    ),

  created_by uuid not null
    references auth.users(id)
    on delete cascade,

  is_pinned boolean not null
    default false,

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now()
);

create index if not exists
  colab_quick_notes_created_by_idx
on public.colab_quick_notes(created_by);

create index if not exists
  colab_quick_notes_pinned_idx
on public.colab_quick_notes(is_pinned);

alter table public.colab_quick_notes
enable row level security;

drop policy if exists
  "Authenticated collaborators can read quick notes"
on public.colab_quick_notes;

create policy
  "Authenticated collaborators can read quick notes"
on public.colab_quick_notes
for select
to authenticated
using (
  auth.uid() is not null
);

drop policy if exists
  "Authenticated collaborators can create quick notes"
on public.colab_quick_notes;

create policy
  "Authenticated collaborators can create quick notes"
on public.colab_quick_notes
for insert
to authenticated
with check (
  auth.uid() = created_by
);

drop policy if exists
  "Authenticated collaborators can update quick notes"
on public.colab_quick_notes;

create policy
  "Authenticated collaborators can update quick notes"
on public.colab_quick_notes
for update
to authenticated
using (
  auth.uid() is not null
)
with check (
  auth.uid() is not null
);

drop policy if exists
  "Authenticated collaborators can delete quick notes"
on public.colab_quick_notes;

create policy
  "Authenticated collaborators can delete quick notes"
on public.colab_quick_notes
for delete
to authenticated
using (
  auth.uid() is not null
);

grant
  select,
  insert,
  update,
  delete
on public.colab_quick_notes
to authenticated;
