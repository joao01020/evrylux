import {
  supabase,
} from './supabase';

export type PublicRoadmapStage =
  | 'available'
  | 'development'
  | 'planned';

export type PublicRoadmapItem = {
  id: string;
  title: string;
  stage: PublicRoadmapStage;
  sort_order: number;
  created_at: string;
  updated_at: string;
};

export type PublicRoadmapInput = {
  title: string;
  stage: PublicRoadmapStage;
  sort_order: number;
};

const columns =
  'id, title, stage, sort_order, created_at, updated_at';

export async function getPublicRoadmapItems() {
  const {
    data,
    error,
  } =
    await supabase
      .from(
        'public_roadmap_items',
      )
      .select(columns)
      .order(
        'stage',
        {
          ascending: true,
        },
      )
      .order(
        'sort_order',
        {
          ascending: true,
        },
      );

  if (error) {
    throw error;
  }

  return (
    data ?? []
  ) as PublicRoadmapItem[];
}

export async function createPublicRoadmapItem(
  input: PublicRoadmapInput,
) {
  const {
    data,
    error,
  } =
    await supabase
      .from(
        'public_roadmap_items',
      )
      .insert(input)
      .select(columns)
      .single();

  if (error) {
    throw error;
  }

  return data as PublicRoadmapItem;
}

export async function updatePublicRoadmapItem(
  id: string,
  input: PublicRoadmapInput,
) {
  const {
    data,
    error,
  } =
    await supabase
      .from(
        'public_roadmap_items',
      )
      .update({
        ...input,
        updated_at:
          new Date().toISOString(),
      })
      .eq(
        'id',
        id,
      )
      .select(columns)
      .single();

  if (error) {
    throw error;
  }

  return data as PublicRoadmapItem;
}

export async function deletePublicRoadmapItem(
  id: string,
) {
  const {
    error,
  } =
    await supabase
      .from(
        'public_roadmap_items',
      )
      .delete()
      .eq(
        'id',
        id,
      );

  if (error) {
    throw error;
  }
}
