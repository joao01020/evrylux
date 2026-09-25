import {
  supabase,
} from './supabase';

export type MyRoadmapTask = {
  id: string;
  title: string;
  description: string | null;
  area: string | null;
  stage: string;
  status: string;
  priority: string;
  progress: number;
  due_date: string | null;
  notification_id: string | null;
  notification_is_read: boolean;
  notification_created_at: string | null;
  assigned_by_user_id: string | null;
  assigned_by_name: string | null;
};

function fail(
  error: {
    message?: string;
  } | null,
  fallback: string,
): never {
  throw new Error(
    error?.message ||
    fallback,
  );
}

export async function getMyRoadmapTasks():
  Promise<MyRoadmapTask[]> {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'list_my_colab_roadmap_tasks',
    );

  if (error) {
    fail(
      error,
      'Não foi possível carregar suas tarefas.',
    );
  }

  return (
    Array.isArray(data)
      ? data
      : []
  ) as MyRoadmapTask[];
}

export async function markTaskNotificationRead(
  notificationId: string,
) {
  if (
    !notificationId.trim()
  ) {
    return;
  }

  const {
    error,
  } =
    await supabase.rpc(
      'mark_colab_task_notification_read',
      {
        p_notification_id:
          notificationId,
      },
    );

  if (error) {
    console.warn(
      '[EVRYLUX] Não foi possível marcar a notificação como lida:',
      error.message,
    );
  }
}

// EVRYLUX_TASK_SYNC_REFRESH_V1
//
// Além do INSERT de notificação em tempo real, atualiza silenciosamente
// a lista quando a aba volta ao foco e em intervalo leve.
// Isso corrige mudanças de responsável feitas em outra sessão/dispositivo.
export async function connectTaskAssignments(
  userId: string,
  onAssignment: (
    notificationId: string,
  ) => void | Promise<void>,
): Promise<() => Promise<void>> {
  const normalizedUserId =
    userId.trim();

  if (!normalizedUserId) {
    throw new Error(
      'Usuário inválido para sincronização de tarefas.',
    );
  }

  const channel =
    supabase.channel(
      `evrylux-task-assignments-${normalizedUserId}`,
    );

  let lastPassiveRefreshAt =
    0;

  let passiveRefreshRunning =
    false;

  const runPassiveRefresh =
    async () => {
      const now =
        Date.now();

      if (
        passiveRefreshRunning ||
        (
          now -
          lastPassiveRefreshAt
        ) <
        1500
      ) {
        return;
      }

      passiveRefreshRunning =
        true;

      lastPassiveRefreshAt =
        now;

      try {
        await onAssignment(
          '',
        );
      } catch (
        error
      ) {
        console.warn(
          '[EVRYLUX] Não foi possível sincronizar tarefas:',
          error,
        );
      } finally {
        passiveRefreshRunning =
          false;
      }
    };

  channel.on(
    'postgres_changes',
    {
      event:
        'INSERT',

      schema:
        'public',

      table:
        'colab_task_notifications',

      filter:
        `user_id=eq.${normalizedUserId}`,
    },
    async (
      payload,
    ) => {
      const notificationId =
        String(
          (
            payload.new as {
              id?: string;
            }
          )?.id ??
          '',
        ).trim();

      if (
        notificationId
      ) {
        await onAssignment(
          notificationId,
        );
      }
    },
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
                'Tempo limite ao conectar notificações de tarefas.',
              ),
            );
          },
          10000,
        );

      channel.subscribe(
        (
          status,
        ) => {
          if (
            status ===
            'SUBSCRIBED'
          ) {
            window.clearTimeout(
              timeout,
            );

            resolve();
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
                `Falha nas notificações de tarefas: ${status}`,
              ),
            );
          }
        },
      );
    },
  );

  const handleFocus =
    () => {
      void runPassiveRefresh();
    };

  const handleVisibilityChange =
    () => {
      if (
        document.visibilityState ===
        'visible'
      ) {
        void runPassiveRefresh();
      }
    };

  window.addEventListener(
    'focus',
    handleFocus,
  );

  document.addEventListener(
    'visibilitychange',
    handleVisibilityChange,
  );

  const passiveInterval =
    window.setInterval(
      () => {
        if (
          document.visibilityState ===
          'visible'
        ) {
          void runPassiveRefresh();
        }
      },
      15000,
    );

  return async () => {
    window.clearInterval(
      passiveInterval,
    );

    window.removeEventListener(
      'focus',
      handleFocus,
    );

    document.removeEventListener(
      'visibilitychange',
      handleVisibilityChange,
    );

    await supabase.removeChannel(
      channel,
    );
  };
}
