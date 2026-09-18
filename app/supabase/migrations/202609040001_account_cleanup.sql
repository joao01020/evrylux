-- ============================================================
-- EVRYLUX — ACCOUNT/DATA CLEANUP
-- ============================================================
--
-- Função interna de servidor.
-- NÃO deve ser executável por authenticated/anon.
-- A Edge Function account-cleanup chama esta função usando
-- service_role depois de validar o usuário pelo bearer token.
--
-- ============================================================

create or replace function public.delete_evrylux_user_data_for(
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_table text;
  v_tables text[] := array[
    'routine_comments',
    'board_attachments',
    'task_items',
    'mind_map_nodes',
    'routine_blocks',
    'routine_days',
    'reminders',
    'training_activity_plans',
    'training_data',
    'study_data',
    'finance_contributions',
    'finance_objectives',
    'finance_data',
    'brain_reviews',
    'brain_concepts',
    'brain_notes',
    'brain_objects',
    'brain_device_key_envelopes',
    'brain_device_envelopes',
    'brain_devices',
    'user_devices'
  ];
begin
  if p_user_id is null then
    raise exception 'p_user_id não pode ser nulo.';
  end if;

  foreach v_table in array v_tables
  loop
    if to_regclass('public.' || v_table) is not null
       and exists (
         select 1
         from information_schema.columns
         where table_schema = 'public'
           and table_name = v_table
           and column_name = 'user_id'
       ) then
      execute format(
        'delete from public.%I where user_id = $1',
        v_table
      ) using p_user_id;
    end if;
  end loop;

  -- profiles usa id como FK/PK do usuário.
  if to_regclass('public.profiles') is not null then
    execute 'delete from public.profiles where id = $1'
      using p_user_id;
  end if;
end;
$$;

revoke all
on function public.delete_evrylux_user_data_for(uuid)
from public;

revoke all
on function public.delete_evrylux_user_data_for(uuid)
from anon;

revoke all
on function public.delete_evrylux_user_data_for(uuid)
from authenticated;

-- service_role é usado somente dentro da Edge Function.
grant execute
on function public.delete_evrylux_user_data_for(uuid)
to service_role;

notify pgrst, 'reload schema';
