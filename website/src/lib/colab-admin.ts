import {
  supabase,
} from './supabase';

export type ColabAdmin = {
  user_id: string;
  email: string | null;
  display_name: string | null;
  github_login: string | null;
  created_at: string;
};

export async function isCurrentUserAdmin() {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'is_colab_admin',
    );

  if (error) {
    console.warn(
      '[EVRYLUX] Não foi possível verificar administrador:',
      error.message,
    );

    return false;
  }

  return Boolean(data);
}

export async function getColabAdmins() {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'list_colab_admins',
    );

  if (error) {
    throw error;
  }

  return (
    data ?? []
  ) as ColabAdmin[];
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
    throw error;
  }

  return data;
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
    throw error;
  }

  return data;
}
