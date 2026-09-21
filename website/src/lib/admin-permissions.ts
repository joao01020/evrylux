import {
  supabase,
} from './supabase';

export const ADMIN_PERMISSION_DEFINITIONS = [
  {
    key: 'view_demo',
    label: 'Ver fila do Demo',
    description: 'Pode visualizar inscrições e interessados no Demo.',
    group: 'Demo',
  },
  {
    key: 'manage_demo',
    label: 'Gerenciar fila do Demo',
    description: 'Pode alterar status e administrar entradas do Demo.',
    group: 'Demo',
  },
  {
    key: 'view_support',
    label: 'Ver suporte',
    description: 'Pode visualizar conversas e chamados de suporte.',
    group: 'Suporte',
  },
  {
    key: 'reply_support',
    label: 'Responder suporte',
    description: 'Pode responder usuários pelo portal.',
    group: 'Suporte',
  },
  {
    key: 'edit_roadmap',
    label: 'Editar roadmap',
    description: 'Pode criar, editar e remover itens do roadmap público.',
    group: 'Conteúdo',
  },
  {
    key: 'manage_admins',
    label: 'Gerenciar administradores',
    description: 'Pode adicionar e remover administradores, mas nunca alterar o proprietário.',
    group: 'Administração',
  },
  {
    key: 'view_audit_logs',
    label: 'Ver auditoria',
    description: 'Pode visualizar o histórico das ações administrativas.',
    group: 'Administração',
  },
  {
    key: 'manage_notifications',
    label: 'Gerenciar notificações',
    description: 'Pode operar notificações administrativas.',
    group: 'Administração',
  },
  {
    key: 'manage_site_content',
    label: 'Gerenciar conteúdo do site',
    description: 'Pode administrar conteúdos internos que forem conectados a esta permissão.',
    group: 'Conteúdo',
  },
  {
    key: 'manage_security',
    label: 'Gerenciar segurança',
    description: 'Pode acessar ferramentas administrativas de segurança permitidas.',
    group: 'Segurança',
  },
] as const;

export type AdminPermission =
  typeof ADMIN_PERMISSION_DEFINITIONS[number]['key'];

export interface ColabUserAdminPreview {
  user_id: string;
  email: string | null;
  display_name: string | null;
  avatar_url: string | null;
  is_admin: boolean;
  is_owner: boolean;
  permissions: AdminPermission[];
}

export interface ColabAdmin {
  user_id: string;
  email: string | null;
  display_name: string | null;
  avatar_url: string | null;
  is_owner: boolean;
  permissions: AdminPermission[];
  created_at: string;
  updated_at: string;
}

export interface AdminAuditEntry {
  id: number;
  actor_user_id: string | null;
  actor_email: string | null;
  target_user_id: string | null;
  target_email: string | null;
  action: string;
  details: Record<string, unknown>;
  created_at: string;
}

function normalizeRpcError(
  error: unknown,
  fallback: string,
) {
  if (
    typeof error === 'object' &&
    error !== null &&
    'message' in error &&
    typeof (error as { message?: unknown }).message === 'string'
  ) {
    return new Error(
      (error as { message: string }).message,
    );
  }

  return new Error(
    fallback,
  );
}

export async function isCurrentUserOwner() {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'is_colab_owner',
    );

  if (error) {
    throw normalizeRpcError(
      error,
      'Não foi possível verificar o proprietário.',
    );
  }

  return data === true;
}

export async function hasAdminPermission(
  permission:
    AdminPermission,
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'has_colab_admin_permission',
      {
        permission_name:
          permission,
      },
    );

  if (error) {
    throw normalizeRpcError(
      error,
      'Não foi possível verificar a permissão.',
    );
  }

  return data === true;
}

export async function claimOwner() {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'claim_colab_owner',
    );

  if (error) {
    throw normalizeRpcError(
      error,
      'Não foi possível definir o proprietário.',
    );
  }

  return data === true;
}

export async function listColabAdmins():
  Promise<ColabAdmin[]> {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'list_colab_admins',
    );

  if (error) {
    throw normalizeRpcError(
      error,
      'Não foi possível carregar os administradores.',
    );
  }

  return (
    data ?? []
  ).map(
    (
      row: Record<
        string,
        unknown
      >,
    ) => ({
      user_id:
        String(
          row.user_id ??
          '',
        ),

      email:
        typeof row.email ===
        'string'
          ? row.email
          : null,

      display_name:
        typeof row.display_name ===
        'string'
          ? row.display_name
          : null,

      avatar_url:
        typeof row.avatar_url ===
        'string'
          ? row.avatar_url
          : null,

      is_owner:
        row.is_owner ===
        true,

      permissions:
        Array.isArray(
          row.permissions,
        )
          ? row.permissions.filter(
              (
                permission,
              ): permission is AdminPermission =>
                typeof permission ===
                  'string' &&
                ADMIN_PERMISSION_DEFINITIONS.some(
                  (
                    definition,
                  ) =>
                    definition.key ===
                    permission,
                ),
            )
          : [],

      created_at:
        String(
          row.created_at ??
          '',
        ),

      updated_at:
        String(
          row.updated_at ??
          '',
        ),
    }),
  );
}


export async function lookupColabUserForAdmin(
  email: string,
):
  Promise<
    ColabUserAdminPreview | null
  > {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'lookup_colab_user_for_admin',
      {
        target_email:
          email.trim(),
      },
    );

  if (error) {
    throw normalizeRpcError(
      error,
      'Não foi possível consultar o usuário.',
    );
  }

  const row =
    Array.isArray(data)
      ? data[0]
      : data;

  if (!row) {
    return null;
  }

  return {
    user_id:
      String(
        row.user_id ??
        '',
      ),

    email:
      typeof row.email ===
      'string'
        ? row.email
        : null,

    display_name:
      typeof row.display_name ===
      'string'
        ? row.display_name
        : null,

    avatar_url:
      typeof row.avatar_url ===
      'string'
        ? row.avatar_url
        : null,

    is_admin:
      row.is_admin ===
      true,

    is_owner:
      row.is_owner ===
      true,

    permissions:
      Array.isArray(
        row.permissions,
      )
        ? row.permissions.filter(
            (
              permission,
            ): permission is AdminPermission =>
              typeof permission ===
                'string' &&
              ADMIN_PERMISSION_DEFINITIONS.some(
                (
                  definition,
                ) =>
                  definition.key ===
                  permission,
              ),
          )
        : [],
  };
}

export async function addColabAdminByEmail(
  email: string,
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'add_colab_admin_by_email',
      {
        target_email:
          email.trim(),
      },
    );

  if (error) {
    throw normalizeRpcError(
      error,
      'Não foi possível adicionar o administrador.',
    );
  }

  return String(
    data ??
    '',
  );
}

export async function setColabAdminPermissions(
  userId: string,
  permissions:
    AdminPermission[],
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'set_colab_admin_permissions',
      {
        target_user_id:
          userId,

        new_permissions:
          permissions,
      },
    );

  if (error) {
    throw normalizeRpcError(
      error,
      'Não foi possível salvar as permissões.',
    );
  }

  return data === true;
}

export async function removeColabAdmin(
  userId: string,
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'remove_colab_admin',
      {
        target_user_id:
          userId,
      },
    );

  if (error) {
    throw normalizeRpcError(
      error,
      'Não foi possível remover o administrador.',
    );
  }

  return data === true;
}

export async function listAdminAudit(
  limit = 50,
):
  Promise<
    AdminAuditEntry[]
  > {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'list_colab_admin_audit',
      {
        limit_rows:
          limit,
      },
    );

  if (error) {
    throw normalizeRpcError(
      error,
      'Não foi possível carregar a auditoria.',
    );
  }

  return (
    data ?? []
  ) as AdminAuditEntry[];
}
