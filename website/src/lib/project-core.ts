import { supabase } from './supabase';

export type ProjectCoreNote = {
  id: string;
  title: string;
  content: string;
  is_pinned: boolean;
  sort_order: number;
  created_by: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
};

export type CoreAdmin = {
  user_id: string;
  email: string;
  display_name: string;
  avatar_url: string | null;
  is_owner: boolean;
  permissions: string[];
  created_at: string;
  updated_at: string;
};

function fail(error: { message?: string } | null, fallback: string): never {
  throw new Error(error?.message || fallback);
}

export async function canEditProjectCore() {
  const { data, error } = await supabase.rpc('can_edit_project_core');
  if (error) fail(error, 'Não foi possível verificar a permissão do Núcleo.');
  return data === true;
}

export async function listProjectCoreNotes(): Promise<ProjectCoreNote[]> {
  const { data, error } = await supabase.rpc('list_project_core_notes');
  if (error) fail(error, 'Não foi possível carregar o Núcleo.');
  return (Array.isArray(data) ? data : []) as ProjectCoreNote[];
}

export async function createProjectCoreNote(input: {
  title: string;
  content: string;
  pinned: boolean;
}) {
  const { data, error } = await supabase.rpc('create_project_core_note', {
    note_title: input.title,
    note_content: input.content,
    note_pinned: input.pinned,
  });
  if (error) fail(error, 'Não foi possível criar a nota.');
  return data as string;
}

export async function updateProjectCoreNote(input: {
  id: string;
  title: string;
  content: string;
  pinned: boolean;
}) {
  const { error } = await supabase.rpc('update_project_core_note', {
    note_id: input.id,
    note_title: input.title,
    note_content: input.content,
    note_pinned: input.pinned,
  });
  if (error) fail(error, 'Não foi possível atualizar a nota.');
}

export async function deleteProjectCoreNote(id: string) {
  const { error } = await supabase.rpc('delete_project_core_note', { note_id: id });
  if (error) fail(error, 'Não foi possível excluir a nota.');
}

export async function listCoreAdmins(): Promise<CoreAdmin[]> {
  const { data, error } = await supabase.rpc('list_colab_admins');
  if (error) fail(error, 'Não foi possível carregar os administradores.');
  return (Array.isArray(data) ? data : []) as CoreAdmin[];
}

export async function setCoreEditor(userId: string, allowed: boolean) {
  const { error } = await supabase.rpc('set_project_core_editor', {
    target_user_id: userId,
    allowed,
  });
  if (error) fail(error, 'Não foi possível atualizar a permissão do Núcleo.');
}

export async function isCurrentUserCoreOwner() {
  const { data, error } = await supabase.rpc('is_colab_owner');
  if (error) return false;
  return data === true;
}
