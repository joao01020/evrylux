import {
  supabase,
} from './supabase';

export type ArchitectureNode = {
  id: string;
  slug: string;
  title: string;
  subtitle: string | null;
  summary: string | null;
  description: string | null;
  category: string;
  responsibilities: string[];
  technologies: string[];
  files: string[];
  database_objects: string[];
  sort_order: number;
  created_at: string;
  updated_at: string;
};

export type ArchitectureHistoryEntry = {
  id: string;
  title: string;
  description: string;
  category: string;
  components: string[];
  files: string[];
  database_objects: string[];
  source_url: string | null;
  occurred_at: string;
  created_by: string;
  created_at: string;
};

export const architectureCategoryLabels:
  Record<string, string> = {
    architecture: 'Arquitetura',
    database: 'Banco de dados',
    security: 'Segurança',
    sync: 'Sincronização',
    frontend: 'Frontend',
    backend: 'Backend',
    infrastructure: 'Infraestrutura',
    migration: 'Migração',
    decision: 'Decisão técnica',
    deprecation: 'Depreciação',
  };

function fail(
  error: any,
  fallback: string,
): never {
  throw new Error(
    error?.message ||
    fallback,
  );
}

function normalizeRows<T>(
  data: unknown,
): T[] {
  return (
    Array.isArray(data)
      ? data
      : []
  ) as T[];
}

export async function getArchitectureNodes(): Promise<
  ArchitectureNode[]
> {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'list_colab_architecture_nodes',
    );

  if (error) {
    fail(
      error,
      'Não foi possível carregar o mapa da arquitetura.',
    );
  }

  return normalizeRows<
    ArchitectureNode
  >(
    data,
  );
}

export async function getArchitectureHistory(): Promise<
  ArchitectureHistoryEntry[]
> {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'list_colab_architecture_history',
    );

  if (error) {
    fail(
      error,
      'Não foi possível carregar a linha do tempo da arquitetura.',
    );
  }

  return normalizeRows<
    ArchitectureHistoryEntry
  >(
    data,
  );
}

export async function addArchitectureHistoryEntry(
  input: {
    title: string;
    description: string;
    category: string;
    components: string[];
    files: string[];
    databaseObjects: string[];
    sourceUrl?: string | null;
    occurredAt: string;
  },
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'add_colab_architecture_history_entry',
      {
        p_title:
          input.title,

        p_description:
          input.description,

        p_category:
          input.category,

        p_components:
          input.components,

        p_files:
          input.files,

        p_database_objects:
          input.databaseObjects,

        p_source_url:
          input.sourceUrl ||
          null,

        p_occurred_at:
          input.occurredAt,
      },
    );

  if (error) {
    fail(
      error,
      'Não foi possível registrar a mudança arquitetural.',
    );
  }

  return data as string;
}


export async function updateArchitectureNode(
  input: {
    id: string;
    title: string;
    subtitle?: string | null;
    summary?: string | null;
    description?: string | null;
    category: string;
    responsibilities: string[];
    technologies: string[];
    files: string[];
    databaseObjects: string[];
  },
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'update_colab_architecture_node',
      {
        p_node_id: input.id,
        p_title: input.title,
        p_subtitle: input.subtitle || null,
        p_summary: input.summary || null,
        p_description: input.description || null,
        p_category: input.category,
        p_responsibilities: input.responsibilities,
        p_technologies: input.technologies,
        p_files: input.files,
        p_database_objects: input.databaseObjects,
      },
    );

  if (error) {
    fail(
      error,
      'Não foi possível atualizar o componente da arquitetura.',
    );
  }

  return data as string;
}
