import {
  supabase,
} from './supabase';

export type SupportSender =
  | 'user'
  | 'admin';

export type SupportTicketStatus =
  | 'open'
  | 'closed';

export type PublicSupportMessage = {
  id: string;
  sender_type: SupportSender;
  body: string;
  created_at: string;
};

export type AdminSupportTicket = {
  id: string;
  public_token: string;
  email: string | null;
  status: SupportTicketStatus;
  created_at: string;
  updated_at: string;
  last_user_message_at: string | null;
  last_admin_message_at: string | null;
};

export type AdminSupportMessage = {
  id: string;
  ticket_id: string;
  sender_type: SupportSender;
  body: string;
  admin_user_id: string | null;
  created_at: string;
  read_by_admin_at: string | null;
};

export function generateSupportToken() {
  const bytes =
    new Uint8Array(
      32,
    );

  crypto.getRandomValues(
    bytes,
  );

  return Array.from(
    bytes,
  )
    .map(
      (
        value,
      ) =>
        value
          .toString(
            16,
          )
          .padStart(
            2,
            '0',
          ),
    )
    .join('');
}

export async function createSupportTicket(
  token: string,
  firstMessage: string,
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'create_public_support_ticket',
      {
        p_public_token:
          token,
        p_body:
          firstMessage,
      },
    );

  if (error) {
    throw error;
  }

  return data as string;
}

export async function sendPublicSupportMessage(
  token: string,
  body: string,
) {
  const {
    error,
  } =
    await supabase.rpc(
      'send_public_support_message',
      {
        p_public_token:
          token,
        p_body:
          body,
      },
    );

  if (error) {
    throw error;
  }
}

export async function saveSupportEmail(
  token: string,
  email: string,
) {
  const {
    error,
  } =
    await supabase.rpc(
      'set_public_support_email',
      {
        p_public_token:
          token,
        p_email:
          email,
      },
    );

  if (error) {
    throw error;
  }
}

export async function getPublicSupportMessages(
  token: string,
) {
  const {
    data,
    error,
  } =
    await supabase.rpc(
      'get_public_support_messages',
      {
        p_public_token:
          token,
      },
    );

  if (error) {
    throw error;
  }

  return (
    data ?? []
  ) as PublicSupportMessage[];
}

export function openPublicSupportChannel(
  token: string,
  onAdminReply: (
    message:
      PublicSupportMessage,
  ) => void,
) {
  const channel =
    supabase.channel(
      `support:${token}`,
      {
        config: {
          broadcast: {
            ack:
              false,
          },
        },
      },
    );

  channel.on(
    'broadcast',
    {
      event:
        'support_reply',
    },
    (
      payload,
    ) => {
      const message =
        payload.payload as
          PublicSupportMessage;

      onAdminReply(
        message,
      );
    },
  );

  channel.subscribe();

  return {
    channel,

    async disconnect() {
      await supabase.removeChannel(
        channel,
      );
    },
  };
}

export async function getAdminSupportTickets() {
  const {
    data,
    error,
  } =
    await supabase
      .from(
        'support_tickets',
      )
      .select(
        'id, public_token, email, status, created_at, updated_at, last_user_message_at, last_admin_message_at',
      )
      .order(
        'updated_at',
        {
          ascending:
            false,
        },
      );

  if (error) {
    throw error;
  }

  return (
    data ?? []
  ) as AdminSupportTicket[];
}

export async function getAdminSupportMessages(
  ticketId: string,
) {
  const {
    data,
    error,
  } =
    await supabase
      .from(
        'support_messages',
      )
      .select(
        'id, ticket_id, sender_type, body, admin_user_id, created_at, read_by_admin_at',
      )
      .eq(
        'ticket_id',
        ticketId,
      )
      .order(
        'created_at',
        {
          ascending:
            true,
        },
      );

  if (error) {
    throw error;
  }

  return (
    data ?? []
  ) as AdminSupportMessage[];
}

export async function sendAdminSupportReply(
  ticket:
    AdminSupportTicket,
  body: string,
  adminUserId: string,
) {
  const createdAt =
    new Date().toISOString();

  const {
    data,
    error,
  } =
    await supabase
      .from(
        'support_messages',
      )
      .insert({
        ticket_id:
          ticket.id,
        sender_type:
          'admin',
        body,
        admin_user_id:
          adminUserId,
      })
      .select(
        'id, ticket_id, sender_type, body, admin_user_id, created_at, read_by_admin_at',
      )
      .single();

  if (error) {
    throw error;
  }

  await supabase
    .from(
      'support_tickets',
    )
    .update({
      updated_at:
        createdAt,
      last_admin_message_at:
        createdAt,
    })
    .eq(
      'id',
      ticket.id,
    );

  const broadcast =
    supabase.channel(
      `support:${ticket.public_token}`,
    );

  await new Promise<void>(
    (
      resolve,
    ) => {
      broadcast.subscribe(
        async (
          status,
        ) => {
          if (
            status !==
            'SUBSCRIBED'
          ) {
            return;
          }

          await broadcast.send({
            type:
              'broadcast',
            event:
              'support_reply',
            payload: {
              id:
                data.id,
              sender_type:
                'admin',
              body:
                data.body,
              created_at:
                data.created_at,
            },
          });

          await supabase.removeChannel(
            broadcast,
          );

          resolve();
        },
      );
    },
  );

  return data as AdminSupportMessage;
}

export async function markTicketRead(
  ticketId: string,
) {
  const {
    error,
  } =
    await supabase
      .from(
        'support_messages',
      )
      .update({
        read_by_admin_at:
          new Date().toISOString(),
      })
      .eq(
        'ticket_id',
        ticketId,
      )
      .eq(
        'sender_type',
        'user',
      )
      .is(
        'read_by_admin_at',
        null,
      );

  if (error) {
    throw error;
  }
}

export async function setSupportTicketStatus(
  ticketId: string,
  status:
    SupportTicketStatus,
) {
  const {
    error,
  } =
    await supabase
      .from(
        'support_tickets',
      )
      .update({
        status,
        updated_at:
          new Date().toISOString(),
      })
      .eq(
        'id',
        ticketId,
      );

  if (error) {
    throw error;
  }
}

export async function getUnreadSupportCount() {
  const {
    count,
    error,
  } =
    await supabase
      .from(
        'support_messages',
      )
      .select(
        'id',
        {
          count:
            'exact',
          head:
            true,
        },
      )
      .eq(
        'sender_type',
        'user',
      )
      .is(
        'read_by_admin_at',
        null,
      );

  if (error) {
    throw error;
  }

  return count ?? 0;
}

export function subscribeAdminSupportNotifications(
  onMessage: () => void,
) {
  const channel =
    supabase
      .channel(
        'evrylux-admin-support-notifications',
      )
      .on(
        'postgres_changes',
        {
          event:
            'INSERT',
          schema:
            'public',
          table:
            'support_messages',
          filter:
            'sender_type=eq.user',
        },
        () => {
          onMessage();
        },
      )
      .subscribe();

  return {
    async disconnect() {
      await supabase.removeChannel(
        channel,
      );
    },
  };
}
