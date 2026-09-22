import {
  supabase,
} from './supabase';

export type RoadmapAssigneeMap =
  Record<string, string[]>;

export async function getRoadmapAssigneeMap():
  Promise<RoadmapAssigneeMap> {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'list_colab_roadmap_assignees',
    );

  if (error) {
    throw new Error(
      error.message ||
      'Não foi possível carregar os responsáveis do Roadmap.',
    );
  }

  const map:
    RoadmapAssigneeMap =
      {};

  (
    Array.isArray(data)
      ? data
      : []
  ).forEach(
    (
      row: any,
    ) => {
      const itemId =
        String(
          row.roadmap_item_id ??
          '',
        );

      const userId =
        String(
          row.user_id ??
          '',
        );

      if (
        !itemId ||
        !userId
      ) {
        return;
      }

      if (
        !map[itemId]
      ) {
        map[itemId] =
          [];
      }

      if (
        !map[itemId].includes(
          userId,
        )
      ) {
        map[itemId].push(
          userId,
        );
      }
    },
  );

  return map;
}

export async function setRoadmapAssignees(
  roadmapItemId: string,
  userIds: string[],
) {
  const normalized =
    Array.from(
      new Set(
        userIds
          .map(
            (
              id,
            ) =>
              id.trim(),
          )
          .filter(Boolean),
      ),
    );

  const {
    error,
  } =
    await supabase.rpc(
      'set_colab_roadmap_assignees',
      {
        p_roadmap_item_id:
          roadmapItemId,
        p_user_ids:
          normalized,
      },
    );

  if (error) {
    throw new Error(
      error.message ||
      'Não foi possível salvar os responsáveis do Roadmap.',
    );
  }
}
