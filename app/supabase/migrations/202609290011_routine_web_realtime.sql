-- EVRYLUX Routine Web
-- Habilita eventos Realtime das tabelas compartilhadas da Rotina.
-- RLS continua sendo a autoridade de acesso.

do $$
declare
  table_name text;
begin
  foreach table_name in array array[
    'routine_days',
    'routine_blocks',
    'task_items',
    'mind_map_nodes',
    'routine_comments',
    'board_attachments',
    'reminders'
  ]
  loop
    if to_regclass('public.' || table_name) is not null
       and not exists (
         select 1
         from pg_publication_tables
         where pubname = 'supabase_realtime'
           and schemaname = 'public'
           and tablename = table_name
       ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        table_name
      );
    end if;
  end loop;
end
$$;
