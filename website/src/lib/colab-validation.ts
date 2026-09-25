import { supabase } from './supabase';

export type ValidationStatus =
  | 'untested'
  | 'testing'
  | 'validated'
  | 'review'
  | 'removal'
  | 'removed';

export type ValidationVote =
  | 'keep'
  | 'review'
  | 'remove';

export type ValidationHistoryPhase =
  | 'planning'
  | 'implementation'
  | 'test'
  | 'fix'
  | 'retest'
  | 'validation'
  | 'review'
  | 'removal'
  | 'observation';

export type ValidationHistoryResult =
  | 'pending'
  | 'success'
  | 'partial'
  | 'problem'
  | 'info';

export type ValidationHistoryEntry = {
  id: string;
  validation_item_id: string;
  phase: ValidationHistoryPhase;
  title: string;
  description: string | null;
  result: ValidationHistoryResult;
  created_by: string;
  created_at: string;
};

export type ValidationAttachment = {
  id: string;
  validation_item_id: string;
  storage_path: string;
  file_name: string;
  mime_type: string;
  file_size: number;
  created_by: string;
  created_at: string;
};

const VALIDATION_ATTACHMENT_BUCKET =
  'colab-validation-files';

const MAX_VALIDATION_MARKDOWN_BYTES =
  2 * 1024 * 1024;

export const validationHistoryPhaseLabels:
  Record<ValidationHistoryPhase,string> = {
    planning: 'Planejamento',
    implementation: 'Implementação',
    test: 'Teste',
    fix: 'Correção',
    retest: 'Novo teste',
    validation: 'Validação',
    review: 'Revisão',
    removal: 'Remoção',
    observation: 'Observação',
  };

export const validationHistoryResultLabels:
  Record<ValidationHistoryResult,string> = {
    pending: 'Pendente',
    success: 'Concluído',
    partial: 'Parcial',
    problem: 'Problema',
    info: 'Informativo',
  };

export type ValidationItem = {
  id: string;
  roadmap_item_id: string | null;
  source_type: 'roadmap' | 'direct';
  title: string;
  description: string | null;
  area: string | null;
  assignee_user_id: string | null;
  validation_status: ValidationStatus;
  test_notes: string | null;
  removal_reason: string | null;
  created_by: string;
  test_started_at: string | null;
  validated_at: string | null;
  removed_at: string | null;
  created_at: string;
  updated_at: string;
  vote_keep: number;
  vote_review: number;
  vote_remove: number;
  my_vote: ValidationVote | null;
};

export const validationStatusLabels:
  Record<ValidationStatus,string> = {
    untested: 'Não testado',
    testing: 'Em teste',
    validated: 'Validado',
    review: 'Revisar',
    removal: 'Remover?',
    removed: 'Removido',
  };

function fail(error: any, fallback: string): never {
  throw new Error(error?.message || fallback);
}

export async function getValidationItems(): Promise<ValidationItem[]> {
  const { data, error } =
    await supabase.rpc('list_colab_validation_items');

  if (error) {
    fail(error, 'Não foi possível carregar a Validação.');
  }

  return (Array.isArray(data) ? data : []).map((item: any) => ({
    ...item,
    vote_keep: Number(item.vote_keep || 0),
    vote_review: Number(item.vote_review || 0),
    vote_remove: Number(item.vote_remove || 0),
  })) as ValidationItem[];
}

export async function sendRoadmapToValidation(item: {
  id: string;
  title: string;
  description?: string | null;
  area?: string | null;
  assignee_user_id?: string | null;
}) {
  const { data, error } =
    await supabase.rpc(
      'send_roadmap_item_to_validation',
      {
        p_roadmap_item_id: item.id,
        p_title: item.title,
        p_description: item.description ?? null,
        p_area: item.area ?? null,
        p_assignee_user_id: item.assignee_user_id ?? null,
      },
    );

  if (error) {
    fail(error, 'Não foi possível enviar para validação.');
  }

  return data as string;
}


export async function createValidationItem(
  input: {
    title: string;
    description?: string | null;
    area?: string | null;
    assignee_user_id?: string | null;
  },
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'create_colab_validation_item',
      {
        p_title:
          input.title,
        p_description:
          input.description ?? null,
        p_area:
          input.area ?? null,
        p_assignee_user_id:
          input.assignee_user_id ?? null,
      },
    );

  if (error) {
    fail(
      error,
      'Não foi possível adicionar a função.',
    );
  }

  return data as string;
}



export async function editValidationItem(
  input: {
    id: string;
    title: string;
    description?: string | null;
    area?: string | null;
    assignee_user_id?: string | null;
  },
) {
  const {
    error,
  } =
    await supabase.rpc(
      'edit_colab_validation_item',
      {
        p_validation_id:
          input.id,
        p_title:
          input.title,
        p_description:
          input.description ?? null,
        p_area:
          input.area ?? null,
        p_assignee_user_id:
          input.assignee_user_id ?? null,
      },
    );

  if (error) {
    fail(
      error,
      'Não foi possível editar a função.',
    );
  }
}

export async function updateValidation(
  id: string,
  status: 'untested' | 'testing' | 'validated' | 'review',
  notes: string | null,
) {
  const { error } =
    await supabase.rpc(
      'update_colab_validation',
      {
        p_validation_id: id,
        p_status: status,
        p_notes: notes,
      },
    );

  if (error) {
    fail(error, 'Não foi possível atualizar a validação.');
  }
}

export async function proposeRemoval(id: string, reason: string) {
  const { error } =
    await supabase.rpc(
      'propose_colab_validation_removal',
      {
        p_validation_id: id,
        p_reason: reason,
      },
    );

  if (error) {
    fail(error, 'Não foi possível abrir a proposta de remoção.');
  }
}

export async function voteValidation(id: string, vote: ValidationVote) {
  const { error } =
    await supabase.rpc(
      'vote_colab_validation',
      {
        p_validation_id: id,
        p_vote: vote,
      },
    );

  if (error) {
    fail(error, 'Não foi possível registrar o voto.');
  }
}

export async function canFinalizeValidation() {
  const { data, error } =
    await supabase.rpc('can_finalize_colab_validation');

  if (error) {
    return false;
  }

  return data === true;
}

export async function finalizeValidation(
  id: string,
  decision: 'validated' | 'review' | 'removed',
) {
  const { error } =
    await supabase.rpc(
      'finalize_colab_validation',
      {
        p_validation_id: id,
        p_decision: decision,
      },
    );

  if (error) {
    fail(error, 'Não foi possível confirmar a decisão.');
  }
}

export async function getValidationHistory(): Promise<ValidationHistoryEntry[]> {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'list_colab_validation_history',
    );

  if (error) {
    fail(
      error,
      'Não foi possível carregar o histórico da validação.',
    );
  }

  return (
    Array.isArray(data)
      ? data
      : []
  ) as ValidationHistoryEntry[];
}

export async function addValidationHistoryEntry(
  input: {
    validation_item_id: string;
    phase: ValidationHistoryPhase;
    title: string;
    description?: string | null;
    result: ValidationHistoryResult;
  },
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'add_colab_validation_history_entry',
      {
        p_validation_id:
          input.validation_item_id,

        p_phase:
          input.phase,

        p_title:
          input.title,

        p_description:
          input.description ?? null,

        p_result:
          input.result,
      },
    );

  if (error) {
    fail(
      error,
      'Não foi possível registrar a etapa.',
    );
  }

  return data as string;
}



export async function getValidationAttachments(): Promise<ValidationAttachment[]> {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'list_colab_validation_attachments',
    );

  if (error) {
    fail(
      error,
      'Não foi possível carregar os arquivos técnicos.',
    );
  }

  return (
    Array.isArray(data)
      ? data
      : []
  ) as ValidationAttachment[];
}

function safeMarkdownFileName(
  name: string,
) {
  const withoutPath =
    name
      .split(/[\\/]/)
      .pop() ||
    'documentacao.md';

  const cleaned =
    withoutPath
      .normalize('NFKD')
      .replace(
        /[\u0300-\u036f]/g,
        '',
      )
      .replace(
        /[^a-zA-Z0-9._-]+/g,
        '-',
      )
      .replace(
        /-+/g,
        '-',
      )
      .replace(
        /^[-.]+|[-.]+$/g,
        '',
      );

  const base =
    cleaned ||
    'documentacao.md';

  return base
    .toLowerCase()
    .endsWith('.md')
      ? base
      : `${base}.md`;
}

export async function uploadValidationMarkdownAttachment(
  validationItemId: string,
  file: File,
) {
  if (
    !validationItemId
  ) {
    throw new Error(
      'Item de validação inválido.',
    );
  }

  const fileName =
    safeMarkdownFileName(
      file.name,
    );

  if (
    !fileName
      .toLowerCase()
      .endsWith('.md')
  ) {
    throw new Error(
      'Envie somente arquivos .md.',
    );
  }

  if (
    file.size <=
    0
  ) {
    throw new Error(
      'O arquivo está vazio.',
    );
  }

  if (
    file.size >
    MAX_VALIDATION_MARKDOWN_BYTES
  ) {
    throw new Error(
      'O arquivo .md pode ter no máximo 2 MB.',
    );
  }

  const {
    data: authData,
    error: authError,
  } =
    await supabase.auth.getUser();

  if (
    authError ||
    !authData.user
  ) {
    throw new Error(
      'Sessão autenticada necessária.',
    );
  }

  const randomPart =
    typeof crypto !== 'undefined' &&
    'randomUUID' in crypto
      ? crypto.randomUUID()
      : Math.random()
          .toString(36)
          .slice(2);

  const storagePath =
    [
      authData.user.id,
      validationItemId,
      `${Date.now()}-${randomPart}-${fileName}`,
    ].join('/');

  const {
    error: uploadError,
  } =
    await supabase
      .storage
      .from(
        VALIDATION_ATTACHMENT_BUCKET,
      )
      .upload(
        storagePath,
        file,
        {
          cacheControl:
            '3600',

          contentType:
            'text/markdown',

          upsert:
            false,
        },
      );

  if (
    uploadError
  ) {
    fail(
      uploadError,
      'Não foi possível enviar o arquivo .md.',
    );
  }

  const {
    data,
    error,
  } =
    await supabase.rpc(
      'register_colab_validation_attachment',
      {
        p_validation_id:
          validationItemId,

        p_storage_path:
          storagePath,

        p_file_name:
          fileName,

        p_mime_type:
          'text/markdown',

        p_file_size:
          file.size,
      },
    );

  if (
    error
  ) {
    await supabase
      .storage
      .from(
        VALIDATION_ATTACHMENT_BUCKET,
      )
      .remove([
        storagePath,
      ]);

    fail(
      error,
      'Não foi possível registrar o arquivo técnico.',
    );
  }

  return data as string;
}

export async function downloadValidationMarkdownAttachment(
  storagePath: string,
) {
  const {
    data,
    error,
  } =
    await supabase
      .storage
      .from(
        VALIDATION_ATTACHMENT_BUCKET,
      )
      .download(
        storagePath,
      );

  if (
    error ||
    !data
  ) {
    fail(
      error,
      'Não foi possível baixar o arquivo .md.',
    );
  }

  return data as Blob;
}

/**
 * Remove um item da lista ativa de Validação sem apagar o histórico físico.
 *
 * - item vindo do Roadmap: deixa a Validação e pode voltar a aparecer no Roadmap;
 * - item criado diretamente: desaparece da lista ativa;
 * - histórico/anexos permanecem preservados no banco.
 */
export async function archiveValidationItem(
  id: string,
) {
  const {
    error,
  } =
    await supabase.rpc(
      'archive_colab_validation_item',
      {
        p_validation_id:
          id,
      },
    );

  if (error) {
    fail(
      error,
      'Não foi possível remover a função da lista.',
    );
  }
}

