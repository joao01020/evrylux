create extension if not exists pgcrypto;

-- ============================================================
-- TICKETS
-- ============================================================

create table if not exists public.support_tickets (
  id uuid primary key
    default gen_random_uuid(),

  public_token text not null
    unique,

  email text,

  status text not null
    default 'open'
    check (
      status in (
        'open',
        'closed'
      )
    ),

  created_at timestamptz not null
    default now(),

  updated_at timestamptz not null
    default now(),

  last_user_message_at timestamptz,

  last_admin_message_at timestamptz
);

create index if not exists
  support_tickets_updated_idx
on public.support_tickets (
  updated_at desc
);

alter table public.support_tickets
enable row level security;

-- Somente admins leem/alteram diretamente.
drop policy if exists
  "Admins can read support tickets"
on public.support_tickets;

create policy
  "Admins can read support tickets"
on public.support_tickets
for select
to authenticated
using (
  public.is_colab_admin()
);

drop policy if exists
  "Admins can update support tickets"
on public.support_tickets;

create policy
  "Admins can update support tickets"
on public.support_tickets
for update
to authenticated
using (
  public.is_colab_admin()
)
with check (
  public.is_colab_admin()
);

grant select, update
on public.support_tickets
to authenticated;

-- ============================================================
-- MENSAGENS
-- ============================================================

create table if not exists public.support_messages (
  id uuid primary key
    default gen_random_uuid(),

  ticket_id uuid not null
    references public.support_tickets(id)
    on delete cascade,

  sender_type text not null
    check (
      sender_type in (
        'user',
        'admin'
      )
    ),

  body text not null
    check (
      char_length(
        trim(
          body
        )
      ) between 1 and 2000
    ),

  admin_user_id uuid
    references auth.users(id)
    on delete set null,

  created_at timestamptz not null
    default now(),

  read_by_admin_at timestamptz
);

create index if not exists
  support_messages_ticket_idx
on public.support_messages (
  ticket_id,
  created_at
);

create index if not exists
  support_messages_unread_idx
on public.support_messages (
  sender_type,
  read_by_admin_at
);

alter table public.support_messages
enable row level security;

drop policy if exists
  "Admins can read support messages"
on public.support_messages;

create policy
  "Admins can read support messages"
on public.support_messages
for select
to authenticated
using (
  public.is_colab_admin()
);

drop policy if exists
  "Admins can insert support messages"
on public.support_messages;

create policy
  "Admins can insert support messages"
on public.support_messages
for insert
to authenticated
with check (
  public.is_colab_admin()
  and
  sender_type = 'admin'
  and
  admin_user_id = auth.uid()
);

drop policy if exists
  "Admins can update support messages"
on public.support_messages;

create policy
  "Admins can update support messages"
on public.support_messages
for update
to authenticated
using (
  public.is_colab_admin()
)
with check (
  public.is_colab_admin()
);

grant select, insert, update
on public.support_messages
to authenticated;

-- ============================================================
-- RPC PÚBLICA: CRIAR TICKET
-- ============================================================

create or replace function public.create_public_support_ticket(
  p_public_token text,
  p_body text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_ticket_id uuid;
  now_value timestamptz := now();
begin
  if char_length(trim(p_public_token)) < 40 then
    raise exception 'Token inválido.';
  end if;

  if char_length(trim(p_body)) < 1
     or char_length(trim(p_body)) > 2000 then
    raise exception 'Mensagem inválida.';
  end if;

  insert into public.support_tickets (
    public_token,
    status,
    created_at,
    updated_at,
    last_user_message_at
  )
  values (
    p_public_token,
    'open',
    now_value,
    now_value,
    now_value
  )
  returning id
  into new_ticket_id;

  insert into public.support_messages (
    ticket_id,
    sender_type,
    body,
    created_at
  )
  values (
    new_ticket_id,
    'user',
    trim(p_body),
    now_value
  );

  return new_ticket_id;
end;
$$;

grant execute
on function public.create_public_support_ticket(text, text)
to anon, authenticated;

-- ============================================================
-- RPC PÚBLICA: ENVIAR MENSAGEM
-- ============================================================

create or replace function public.send_public_support_message(
  p_public_token text,
  p_body text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  target_ticket_id uuid;
  now_value timestamptz := now();
begin
  if char_length(trim(p_body)) < 1
     or char_length(trim(p_body)) > 2000 then
    raise exception 'Mensagem inválida.';
  end if;

  select id
  into target_ticket_id
  from public.support_tickets
  where public_token = p_public_token
    and status = 'open'
  limit 1;

  if target_ticket_id is null then
    raise exception 'Atendimento não encontrado ou encerrado.';
  end if;

  insert into public.support_messages (
    ticket_id,
    sender_type,
    body,
    created_at
  )
  values (
    target_ticket_id,
    'user',
    trim(p_body),
    now_value
  );

  update public.support_tickets
  set
    updated_at = now_value,
    last_user_message_at = now_value
  where id = target_ticket_id;

  return true;
end;
$$;

grant execute
on function public.send_public_support_message(text, text)
to anon, authenticated;

-- ============================================================
-- RPC PÚBLICA: SALVAR E-MAIL
-- ============================================================

create or replace function public.set_public_support_email(
  p_public_token text,
  p_email text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if char_length(trim(p_email)) < 5
     or char_length(trim(p_email)) > 180
     or position('@' in p_email) = 0 then
    raise exception 'E-mail inválido.';
  end if;

  update public.support_tickets
  set
    email = trim(p_email),
    updated_at = now()
  where public_token = p_public_token;

  if not found then
    raise exception 'Atendimento não encontrado.';
  end if;

  return true;
end;
$$;

grant execute
on function public.set_public_support_email(text, text)
to anon, authenticated;

-- ============================================================
-- RPC PÚBLICA: HISTÓRICO DO PRÓPRIO TICKET PELO TOKEN
-- O token é aleatório de 256 bits e funciona como segredo da conversa.
-- ============================================================

create or replace function public.get_public_support_messages(
  p_public_token text
)
returns table (
  id uuid,
  sender_type text,
  body text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    m.id,
    m.sender_type,
    m.body,
    m.created_at
  from public.support_messages m
  join public.support_tickets t
    on t.id = m.ticket_id
  where t.public_token = p_public_token
  order by m.created_at asc;
$$;

grant execute
on function public.get_public_support_messages(text)
to anon, authenticated;

-- ============================================================
-- REALTIME PARA NOTIFICAÇÕES DOS ADMINS
-- ============================================================

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'support_messages'
  ) then
    alter publication supabase_realtime
      add table public.support_messages;
  end if;
end
$$;
