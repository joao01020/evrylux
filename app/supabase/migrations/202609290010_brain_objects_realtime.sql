-- EVRYLUX
-- Enable Supabase Realtime for encrypted Brain objects.
-- RLS remains authoritative; the event only signals that the row changed.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'brain_objects'
  ) then
    alter publication supabase_realtime
      add table public.brain_objects;
  end if;
end
$$;
