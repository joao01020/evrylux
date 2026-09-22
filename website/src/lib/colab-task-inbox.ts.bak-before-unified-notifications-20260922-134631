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

export async function connectTaskAssignments(
  userId: string,
  onAssignment: (
    notificationId: string,
  ) => void | Promise<void>,
): Promise<() => Promise<void>> {
  const channel =
    supabase.channel(
      `evrylux-task-assignments-${userId}`,
    );

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
        `user_id=eq.${userId}`,
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

  return async () => {
    await supabase.removeChannel(
      channel,
    );
  };
}
