import {
  supabase,
} from './supabase';

export type ColabPresenceUser = {
  user_id: string;
  display_name: string;
  github_login: string | null;
  avatar_url: string | null;
  area: string | null;
  online_at: string;
};

type PresenceRecord =
  ColabPresenceUser & {
    presence_ref?: string;
  };

type PresenceState =
  Record<
    string,
    PresenceRecord[]
  >;

type PresenceListener =
  (
    users: ColabPresenceUser[],
  ) => void;

const CHANNEL_NAME =
  'evrylux-colab-presence';

export async function connectColabPresence(
  user: ColabPresenceUser,
  onChange: PresenceListener,
) {
  const channel =
    supabase.channel(
      CHANNEL_NAME,
      {
        config: {
          presence: {
            key: user.user_id,
          },
        },
      },
    );

  const emitPresence =
    () => {
      const state =
        channel.presenceState() as PresenceState;

      const usersById =
        new Map<
          string,
          ColabPresenceUser
        >();

      Object.values(
        state,
      ).forEach(
        (entries) => {
          entries.forEach(
            (entry) => {
              if (!entry.user_id) {
                return;
              }

              usersById.set(
                entry.user_id,
                {
                  user_id:
                    entry.user_id,
                  display_name:
                    entry.display_name,
                  github_login:
                    entry.github_login ??
                    null,
                  avatar_url:
                    entry.avatar_url ??
                    null,
                  area:
                    entry.area ??
                    null,
                  online_at:
                    entry.online_at,
                },
              );
            },
          );
        },
      );

      const users =
        Array.from(
          usersById.values(),
        ).sort(
          (a, b) =>
            a.display_name.localeCompare(
              b.display_name,
              'pt-BR',
            ),
        );

      onChange(users);
    };

  channel.on(
    'presence',
    {
      event: 'sync',
    },
    emitPresence,
  );

  channel.on(
    'presence',
    {
      event: 'join',
    },
    emitPresence,
  );

  channel.on(
    'presence',
    {
      event: 'leave',
    },
    emitPresence,
  );

  const subscribed =
    new Promise<void>(
      (resolve, reject) => {
        channel.subscribe(
          async (status) => {
            if (
              status ===
              'SUBSCRIBED'
            ) {
              const {
                error,
              } =
                await channel.track(
                  user,
                );

              if (error) {
                reject(error);
                return;
              }

              emitPresence();
              resolve();
              return;
            }

            if (
              status ===
                'CHANNEL_ERROR' ||
              status ===
                'TIMED_OUT'
            ) {
              reject(
                new Error(
                  `Falha ao conectar ao Presence: ${status}`,
                ),
              );
            }
          },
        );
      },
    );

  await subscribed;

  return {
    channel,

    disconnect:
      async () => {
        try {
          await channel.untrack();
        } finally {
          await supabase.removeChannel(
            channel,
          );
        }
      },
  };
}
