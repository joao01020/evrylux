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

type PresenceConnection = {
  disconnect: () => Promise<void>;
};

function normalizePresenceState(
  state: Record<string, unknown[]>,
) {
  const users =
    new Map<
      string,
      ColabPresenceUser
    >();

  Object.values(
    state,
  ).forEach(
    (
      presences,
    ) => {
      (
        Array.isArray(
          presences,
        )
          ? presences
          : []
      ).forEach(
        (
          raw,
        ) => {
          const item =
            raw as Partial<ColabPresenceUser>;

          const userId =
            String(
              item.user_id ??
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
                  item.display_name ??
                  'Colaborador EVRYLUX',
                ),

              avatar_url:
                item.avatar_url
                  ? String(
                      item.avatar_url,
                    )
                  : null,

              area:
                item.area
                  ? String(
                      item.area,
                    )
                  : null,

              github_login:
                item.github_login
                  ? String(
                      item.github_login,
                    )
                  : null,

              online_at:
                item.online_at
                  ? String(
                      item.online_at,
                    )
                  : new Date().toISOString(),
            },
          );
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
  const channel =
    supabase.channel(
      'evrylux-colab-presence',
      {
        config: {
          presence: {
            key:
              currentUser.user_id,
          },
        },
      },
    );

  let initialized =
    false;

  let previousUsers =
    new Map<
      string,
      ColabPresenceUser
    >();

  const syncPresence =
    () => {
      const state =
        channel.presenceState() as Record<
          string,
          unknown[]
        >;

      const users =
        normalizePresenceState(
          state,
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
    };

  channel.on(
    'presence',
    {
      event:
        'sync',
    },
    syncPresence,
  );

  await new Promise<void>(
    (
      resolve,
      reject,
    ) => {
      const timeout =
        window.setTimeout(
          () => {
            reject(
              new Error(
                'Tempo limite ao conectar presença em tempo real.',
              ),
            );
          },
          10000,
        );

      channel.subscribe(
        async (
          status,
        ) => {
          if (
            status ===
            'SUBSCRIBED'
          ) {
            window.clearTimeout(
              timeout,
            );

            try {
              await channel.track(
                {
                  ...currentUser,
                  online_at:
                    new Date().toISOString(),
                },
              );

              resolve();
            } catch (
              error
            ) {
              reject(
                error,
              );
            }
          }

          if (
            status ===
            'CHANNEL_ERROR' ||
            status ===
            'TIMED_OUT'
          ) {
            window.clearTimeout(
              timeout,
            );

            reject(
              new Error(
                `Falha na conexão de presença: ${status}`,
              ),
            );
          }
        },
      );
    },
  );

  return async () => {
    try {
      await channel.untrack();
    } catch {
      // A remoção do canal abaixo também limpa a presença.
    }

    await supabase.removeChannel(
      channel,
    );
  };
}
