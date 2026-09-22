import {
  supabase,
} from './supabase';

export type ColabPresenceUser = {
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  area: string | null;
  github_login: string | null;
  online_at: string;
};

export type ColabPresenceHandlers = {
  onSync?: (
    users: ColabPresenceUser[],
  ) => void;

  onJoin?: (
    user: ColabPresenceUser,
  ) => void;

  onLeave?: (
    user: ColabPresenceUser,
  ) => void;
};

type PresenceRow = {
  user_id: string;
  display_name: string | null;
  avatar_url: string | null;
  area: string | null;
  github_login: string | null;
  online_at: string;
};

const HEARTBEAT_MS =
  15000;

const REFRESH_MS =
  10000;

function normalizeRows(
  rows:
    PresenceRow[] |
    null |
    undefined,
) {
  const users =
    new Map<
      string,
      ColabPresenceUser
    >();

  (
    rows ??
    []
  ).forEach(
    (
      row,
    ) => {
      const userId =
        String(
          row.user_id ??
          '',
        ).trim();

      if (
        !userId
      ) {
        return;
      }

      users.set(
        userId,
        {
          user_id:
            userId,

          display_name:
            String(
              row.display_name ??
              'Colaborador EVRYLUX',
            ),

          avatar_url:
            row.avatar_url
              ? String(
                  row.avatar_url,
                )
              : null,

          area:
            row.area
              ? String(
                  row.area,
                )
              : null,

          github_login:
            row.github_login
              ? String(
                  row.github_login,
                )
              : null,

          online_at:
            String(
              row.online_at ??
              new Date().toISOString(),
            ),
        },
      );
    },
  );

  return Array.from(
    users.values(),
  ).sort(
    (
      a,
      b,
    ) =>
      a.display_name.localeCompare(
        b.display_name,
        'pt-BR',
      ),
  );
}

export async function connectColabPresence(
  currentUser: Omit<
    ColabPresenceUser,
    'online_at'
  >,
  handlers: ColabPresenceHandlers =
    {},
): Promise<() => Promise<void>> {
  const sessionId =
    (
      globalThis.crypto?.randomUUID?.() ??
      `${currentUser.user_id}-${Date.now()}-${Math.random()}`
    );

  let stopped =
    false;

  let refreshing =
    false;

  let previousUsers =
    new Map<
      string,
      ColabPresenceUser
    >();

  let initialized =
    false;

  async function heartbeat() {
    if (
      stopped
    ) {
      return;
    }

    const {
      error,
    } =
      await supabase.rpc(
        'upsert_colab_presence_session',
        {
          p_session_id:
            sessionId,

          p_display_name:
            currentUser.display_name,

          p_avatar_url:
            currentUser.avatar_url,

          p_area:
            currentUser.area,

          p_github_login:
            currentUser.github_login,
        },
      );

    if (
      error
    ) {
      throw error;
    }
  }

  async function refresh() {
    if (
      stopped ||
      refreshing
    ) {
      return;
    }

    refreshing =
      true;

    try {
      const {
        data,
        error,
      } =
        await supabase.rpc(
          'list_active_colab_presence',
        );

      if (
        error
      ) {
        throw error;
      }

      const users =
        normalizeRows(
          (
            data ??
            []
          ) as PresenceRow[],
        );

      const nextUsers =
        new Map(
          users.map(
            (
              user,
            ) => [
              user.user_id,
              user,
            ] as const,
          ),
        );

      handlers.onSync?.(
        users,
      );

      if (
        initialized
      ) {
        nextUsers.forEach(
          (
            user,
            userId,
          ) => {
            if (
              !previousUsers.has(
                userId,
              )
            ) {
              handlers.onJoin?.(
                user,
              );
            }
          },
        );

        previousUsers.forEach(
          (
            user,
            userId,
          ) => {
            if (
              !nextUsers.has(
                userId,
              )
            ) {
              handlers.onLeave?.(
                user,
              );
            }
          },
        );
      }

      previousUsers =
        nextUsers;

      initialized =
        true;
    } finally {
      refreshing =
        false;
    }
  }

  await heartbeat();
  await refresh();

  const heartbeatTimer =
    window.setInterval(
      () => {
        void heartbeat()
          .then(
            refresh,
          )
          .catch(
            (
              error,
            ) => {
              console.warn(
                '[EVRYLUX] Falha ao atualizar presença:',
                error,
              );
            },
          );
      },
      HEARTBEAT_MS,
    );

  const refreshTimer =
    window.setInterval(
      () => {
        void refresh().catch(
          (
            error,
          ) => {
            console.warn(
              '[EVRYLUX] Falha ao consultar usuários online:',
              error,
            );
          },
        );
      },
      REFRESH_MS,
    );

  const onVisibility =
    () => {
      if (
        document.visibilityState ===
        'visible'
      ) {
        void heartbeat()
          .then(
            refresh,
          )
          .catch(
            (
              error,
            ) => {
              console.warn(
                '[EVRYLUX] Falha ao restaurar presença:',
                error,
              );
            },
          );
      }
    };

  document.addEventListener(
    'visibilitychange',
    onVisibility,
  );

  return async () => {
    if (
      stopped
    ) {
      return;
    }

    stopped =
      true;

    window.clearInterval(
      heartbeatTimer,
    );

    window.clearInterval(
      refreshTimer,
    );

    document.removeEventListener(
      'visibilitychange',
      onVisibility,
    );

    try {
      await supabase.rpc(
        'remove_colab_presence_session',
        {
          p_session_id:
            sessionId,
        },
      );
    } catch {
      // Mesmo se o fechamento for interrompido pelo navegador,
      // sessões antigas expiram automaticamente no servidor.
    }
  };
}
