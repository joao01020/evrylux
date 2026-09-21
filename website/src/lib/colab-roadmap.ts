import { supabase } from './supabase';

export type RoadmapStage = 'now' | 'next' | 'later' | 'done';
export type RoadmapStatus = 'todo' | 'in_progress' | 'blocked' | 'done';
export type RoadmapPriority = 'low' | 'medium' | 'high';

export type RoadmapItem = {
  id: string;
  title: string;
  description: string | null;
  stage: RoadmapStage;
  status: RoadmapStatus;
  priority: RoadmapPriority;
  area: string | null;
  progress: number;
  assignee_user_id: string | null;
  created_by: string;
  due_date: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
};

export type RoadmapItemInput = Omit<RoadmapItem, 'id' | 'created_by' | 'created_at' | 'updated_at'>;

export type CollaboratorProfile = {
  user_id: string;
  display_name: string | null;
  github_login: string | null;
  avatar_url: string | null;
  area: string | null;
};

const itemColumns = 'id, title, description, stage, status, priority, area, progress, assignee_user_id, created_by, due_date, notes, created_at, updated_at';

export async function getRoadmapItems() {
  const { data, error } = await supabase.from('colab_roadmap_items').select(itemColumns).order('created_at', { ascending: false });
  if (error) throw error;
  return (data ?? []) as RoadmapItem[];
}

export async function getCollaboratorProfiles() {
  const { data, error } = await supabase.from('member_profiles').select('user_id, display_name, github_login, avatar_url, area').order('display_name', { ascending: true });
  if (error) throw error;
  return (data ?? []) as CollaboratorProfile[];
}

export async function createRoadmapItem(input: RoadmapItemInput, userId: string) {
  const { data, error } = await supabase.from('colab_roadmap_items').insert({ ...input, created_by: userId }).select(itemColumns).single();
  if (error) throw error;
  return data as RoadmapItem;
}

export async function updateRoadmapItem(id: string, input: RoadmapItemInput) {
  const { data, error } = await supabase.from('colab_roadmap_items').update({ ...input, updated_at: new Date().toISOString() }).eq('id', id).select(itemColumns).single();
  if (error) throw error;
  return data as RoadmapItem;
}

export async function deleteRoadmapItem(id: string) {
  const { error } = await supabase.from('colab_roadmap_items').delete().eq('id', id);
  if (error) throw error;
}

export const stageLabels: Record<RoadmapStage, string> = { now: 'Agora', next: 'Próximo', later: 'Depois', done: 'Concluído' };
export const statusLabels: Record<RoadmapStatus, string> = { todo: 'A fazer', in_progress: 'Em andamento', blocked: 'Bloqueado', done: 'Concluído' };
export const priorityLabels: Record<RoadmapPriority, string> = { low: 'Baixa', medium: 'Média', high: 'Alta' };
