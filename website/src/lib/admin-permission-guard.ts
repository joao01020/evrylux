import {
  supabase,
} from './supabase';

import type {
  AdminPermission,
} from './admin-permissions';

export async function requireAdminPermission(
  permission:
    AdminPermission,
  options?: {
    requireAal2?:
      boolean;
    redirectTo?:
      string;
  },
) {
  const redirectTo =
    options?.redirectTo ??
    '/colab';

  const {
    data: sessionData,
  } =
    await supabase.auth.getSession();

  if (
    !sessionData.session
  ) {
    window.location.href =
      `/login?next=${encodeURIComponent(window.location.pathname + window.location.search)}`;

    return false;
  }

  const {
    data: allowed,
    error,
  } =
    await supabase.rpc(
      'has_colab_admin_permission',
      {
        permission_name:
          permission,
      },
    );

  if (
    error ||
    allowed !== true
  ) {
    window.location.href =
      redirectTo;

    return false;
  }

  if (
    options?.requireAal2
  ) {
    const {
      data: aalData,
      error: aalError,
    } =
      await supabase.auth.mfa.getAuthenticatorAssuranceLevel();

    if (
      aalError ||
      aalData.currentLevel !==
        'aal2'
    ) {
      const next =
        window.location.pathname +
        window.location.search;

      window.location.href =
        `/colab/security?next=${encodeURIComponent(next)}`;

      return false;
    }
  }

  return true;
}
