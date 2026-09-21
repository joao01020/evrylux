create extension if not exists pgcrypto;

create table if not exists public.demo_waitlist (
  id uuid primary key
    default gen_random_uuid(),

  full_name text not null
    check (
      char_length(trim(full_name))
      between 2 and 120
    ),

  email text not null,

  platform text not null
    check (
      platform in (
        'linux',
        'windows',
        'macos'
      )
    ),

  interest text not null
    default 'all'
    check (
      interest in (
        'brain',
        'finance',
        'training',
        'routine',
        'all'
      )
    ),

  willing_to_feedback boolean not null
    default false,

  early_explorer boolean not null
    default true,

  status text not null
    default 'waiting'
    check (
      status in (
        'waiting',
        'invited',
        'testing'
      )
    ),

  created_at timestamptz not null
    default now(),

  read_at timestamptz
);

create unique index if not exists
  demo_waitlist_email_unique
on public.demo_waitlist (
  lower(email)
);

create index if not exists
  demo_waitlist_created_at_idx
on public.demo_waitlist (
  created_at desc
);

alter table public.demo_waitlist
enable row level security;

drop policy if exists
  "Anyone can join demo waitlist"
on public.demo_waitlist;

create policy
  "Anyone can join demo waitlist"
on public.demo_waitlist
for insert
to anon, authenticated
with check (
  char_length(
    trim(
      full_name
    )
  ) between 2 and 120
  and
  char_length(
    trim(
      email
    )
  ) between 5 and 180
  and
  early_explorer = true
  and
  status = 'waiting'
  and
  read_at is null
);

drop policy if exists
  "Admins can read demo waitlist"
on public.demo_waitlist;

create policy
  "Admins can read demo waitlist"
on public.demo_waitlist
for select
to authenticated
using (
  public.is_colab_admin()
);

drop policy if exists
  "Admins can update demo waitlist"
on public.demo_waitlist;

create policy
  "Admins can update demo waitlist"
on public.demo_waitlist
for update
to authenticated
using (
  public.is_colab_admin()
)
with check (
  public.is_colab_admin()
);

grant insert
on public.demo_waitlist
to anon, authenticated;

grant select, update
on public.demo_waitlist
to authenticated;
