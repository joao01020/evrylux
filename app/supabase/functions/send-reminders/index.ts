import { createClient } from '@supabase/supabase-js'

// ============================================================
// ENV
// ============================================================

const SUPABASE_URL =
  Deno.env.get(
    'SUPABASE_URL',
  )

const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get(
    'SUPABASE_SERVICE_ROLE_KEY',
  )

const TELEGRAM_BOT_TOKEN =
  Deno.env.get(
    'TELEGRAM_BOT_TOKEN',
  )


// ============================================================
// FALLBACK LEGADO OPCIONAL
// ============================================================
//
// Mantém o bot funcionando para o usuário antigo enquanto
// telegram_connections ainda não estiver preenchida.
//
// IMPORTANTE:
// TELEGRAM_CHAT_ID só será usado quando o reminder.user_id for
// exatamente igual a TELEGRAM_OWNER_USER_ID.
//
// Isso evita que lembretes de outros usuários sejam enviados
// para o Telegram do dono original.
//
// ============================================================

const TELEGRAM_CHAT_ID =
  Deno.env.get(
    'TELEGRAM_CHAT_ID',
  )

const TELEGRAM_OWNER_USER_ID =
  Deno.env.get(
    'TELEGRAM_OWNER_USER_ID',
  )

// ============================================================
// VALIDAR ENV
// ============================================================

if (!SUPABASE_URL) {
  throw new Error(
    'SUPABASE_URL não configurada.',
  )
}

if (!SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error(
    'SUPABASE_SERVICE_ROLE_KEY não configurada.',
  )
}

if (!TELEGRAM_BOT_TOKEN) {
  throw new Error(
    'TELEGRAM_BOT_TOKEN não configurado.',
  )
}

// ============================================================
// SUPABASE
// ============================================================
//
// Usamos Service Role porque esta Edge Function roda no backend
// e precisa processar lembretes de vários usuários.
//
// Por isso TODAS as operações abaixo preservam explicitamente
// user_id para evitar misturar registros entre usuários.
//
// ============================================================

const supabase =
  createClient(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        persistSession:
          false,

        autoRefreshToken:
          false,
      },
    },
  )

// ============================================================
// TYPES
// ============================================================

type ReminderRow = {
  id:
    string

  user_id:
    string

  title:
    string | null

  message:
    string | null

  remind_at:
    string

  notify_telegram:
    boolean

  sent_telegram:
    boolean

  completed:
    boolean
}

type TelegramConnectionRow = {
  user_id:
    string

  chat_id:
    string

  enabled:
    boolean
}

type ReminderError = {
  id:
    string

  user_id:
    string

  error:
    string
}

// ============================================================
// HELPERS
// ============================================================

function asNonEmptyString(
  value:
    unknown,
): string {
  if (
    value ===
      null ||
    value ===
      undefined
  ) {
    return ''
  }

  return String(
    value,
  ).trim()
}

// ============================================================
// FORMATAR DATA
// ============================================================

function formatReminderDate(
  value:
    string,
): string {
  const date =
    new Date(
      value,
    )

  return new Intl.DateTimeFormat(
    'pt-BR',
    {
      timeZone:
        'America/Sao_Paulo',

      day:
        '2-digit',

      month:
        '2-digit',

      year:
        'numeric',

      hour:
        '2-digit',

      minute:
        '2-digit',

      hour12:
        false,
    },
  ).format(
    date,
  )
}

// ============================================================
// MONTAR MENSAGEM
// ============================================================

function buildTelegramMessage(
  reminder:
    ReminderRow,
): string {
  const title =
    asNonEmptyString(
      reminder.title,
    ) ||
    'Lembrete'

  const message =
    asNonEmptyString(
      reminder.message,
    )

  const formattedDate =
    formatReminderDate(
      reminder.remind_at,
    )

  const lines =
    [
      '🔔 Lembrete',
      '',
      `📌 ${title}`,
    ]

  if (
    message.length >
    0
  ) {
    lines.push(
      '',
      message,
    )
  }

  lines.push(
    '',
    `🕐 ${formattedDate}`,
  )

  return lines.join(
    '\n',
  )
}

// ============================================================
// ENVIAR TELEGRAM
// ============================================================

async function sendTelegramMessage({
  chatId,
  text,
}: {
  chatId:
    string

  text:
    string
}): Promise<
  void
> {
  const response =
    await fetch(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      {
        method:
          'POST',

        headers:
          {
            'Content-Type':
              'application/json',
          },

        body:
          JSON.stringify(
            {
              chat_id:
                chatId,

              text,
            },
          ),
      },
    )

  const result =
    await response.json()

  if (
    !response.ok ||
    !result?.ok
  ) {
    throw new Error(
      asNonEmptyString(
        result?.description,
      ) ||
      'Erro ao enviar mensagem para o Telegram.',
    )
  }
}

// ============================================================
// CARREGAR CONEXÕES DO TELEGRAM
// ============================================================
//
// Busca em uma única consulta as conexões dos usuários que têm
// lembretes pendentes.
//
// Estrutura esperada:
//
// public.telegram_connections
//
// user_id uuid primary key
// chat_id text not null
// enabled boolean not null default true
//
// ============================================================

async function loadTelegramConnections(
  userIds:
    string[],
): Promise<
  Map<
    string,
    string
  >
> {
  const result =
    new Map<
      string,
      string
    >()

  if (
    userIds.length ===
    0
  ) {
    return result
  }

  const {
    data,
    error,
  } =
    await supabase
      .from(
        'telegram_connections',
      )
      .select(
        'user_id, chat_id, enabled',
      )
      .in(
        'user_id',
        userIds,
      )
      .eq(
        'enabled',
        true,
      )

  if (
    error
  ) {
    throw error
  }

  const rows =
    (data ?? []) as unknown as TelegramConnectionRow[]

  for (
    const row
    of rows
  ) {
    const userId =
      asNonEmptyString(
        row.user_id,
      )

    const chatId =
      asNonEmptyString(
        row.chat_id,
      )

    if (
      userId.length ===
        0 ||
      chatId.length ===
        0
    ) {
      continue
    }

    result.set(
      userId,
      chatId,
    )
  }

  return result
}

// ============================================================
// RESOLVER CHAT DO USUÁRIO
// ============================================================
//
// Prioridade:
//
// 1. telegram_connections.user_id -> chat_id
// 2. fallback legado SOMENTE para TELEGRAM_OWNER_USER_ID
//
// Nunca usamos TELEGRAM_CHAT_ID global para qualquer usuário.
//
// ============================================================

function resolveTelegramChatId({
  userId,
  connections,
}: {
  userId:
    string

  connections:
    Map<
      string,
      string
    >
}): string | null {
  const connectedChatId =
    asNonEmptyString(
      connections.get(
        userId,
      ),
    )

  if (
    connectedChatId.length >
    0
  ) {
    return connectedChatId
  }

  const ownerUserId =
    asNonEmptyString(
      TELEGRAM_OWNER_USER_ID,
    )

  const legacyChatId =
    asNonEmptyString(
      TELEGRAM_CHAT_ID,
    )

  if (
    ownerUserId.length >
        0 &&
    legacyChatId.length >
        0 &&
    userId ===
        ownerUserId
  ) {
    console.warn(
      `[REMINDER] Usando fallback legado seguro para user_id=${userId}.`,
    )

    return legacyChatId
  }

  return null
}

// ============================================================
// MARCAR COMO ENVIADO
// ============================================================
//
// IMPORTANTE:
//
// Como usamos Service Role, não dependemos de RLS aqui.
//
// Por segurança, o UPDATE exige:
//
// id + user_id
//
// Assim um lembrete nunca pode ser marcado a partir do usuário
// errado.
//
// ============================================================

async function markReminderAsSent(
  reminder:
    ReminderRow,
): Promise<
  void
> {
  const {
    error,
  } =
    await supabase
      .from(
        'reminders',
      )
      .update(
        {
          sent_telegram:
            true,

          updated_at:
            new Date()
              .toISOString(),
        },
      )
      .eq(
        'id',
        reminder.id,
      )
      .eq(
        'user_id',
        reminder.user_id,
      )
      .eq(
        'sent_telegram',
        false,
      )

  if (
    error
  ) {
    throw error
  }
}

// ============================================================
// EDGE FUNCTION
// ============================================================

Deno.serve(
  async (
    _request,
  ) => {
    try {
      const now =
        new Date()
          .toISOString()

      // ========================================================
      // BUSCAR LEMBRETES VENCIDOS
      // ========================================================

      const {
        data,
        error: reminderError,
      } =
        await supabase
          .from(
            'reminders',
          )
          .select(
            '*',
          )
          .eq(
            'completed',
            false,
          )
          .eq(
            'notify_telegram',
            true,
          )
          .eq(
            'sent_telegram',
            false,
          )
          .lte(
            'remind_at',
            now,
          )
          .order(
            'remind_at',
            {
              ascending:
                true,
            },
          )

      if (
        reminderError
      ) {
        throw reminderError
      }

      const reminders =
        (data ?? []) as unknown as ReminderRow[]

      if (
        reminders.length ===
        0
      ) {
        return Response.json(
          {
            ok:
              true,

            found:
              0,

            sent:
              0,

            failed:
              0,

            skipped:
              0,

            message:
              'Nenhum lembrete pendente.',
          },
        )
      }

      // ========================================================
      // USERS
      // ========================================================

      const userIds =
        [
          ...new Set(
            reminders
              .map(
                (
                  reminder,
                ) =>
                  asNonEmptyString(
                    reminder.user_id,
                  ),
              )
              .filter(
                (
                  userId,
                ) =>
                  userId.length >
                  0,
              ),
          ),
        ]

      // ========================================================
      // TELEGRAM CONNECTIONS
      // ========================================================

      const telegramConnections =
        await loadTelegramConnections(
          userIds,
        )

      let sent =
        0

      let skipped =
        0

      const errors:
        ReminderError[] =
          []

      // ========================================================
      // PROCESSAR
      // ========================================================

      for (
        const reminder
        of reminders
      ) {
        const reminderId =
          asNonEmptyString(
            reminder.id,
          )

        const userId =
          asNonEmptyString(
            reminder.user_id,
          )

        try {
          // ====================================================
          // VALIDAR LEMBRETE
          // ====================================================

          if (
            reminderId.length ===
            0
          ) {
            throw new Error(
              'Lembrete sem id.',
            )
          }

          if (
            userId.length ===
            0
          ) {
            throw new Error(
              'Lembrete sem user_id.',
            )
          }

          // ====================================================
          // CHAT DO USUÁRIO
          // ====================================================

          const chatId =
            resolveTelegramChatId(
              {
                userId,
                connections:
                  telegramConnections,
              },
            )

          if (
            !chatId
          ) {
            skipped++

            console.warn(
              `[REMINDER] Usuário ${userId} sem telegram_connections e sem fallback válido. Lembrete ${reminderId} não enviado.`,
            )

            continue
          }

          // ====================================================
          // MENSAGEM
          // ====================================================

          const telegramMessage =
            buildTelegramMessage(
              reminder,
            )

          // ====================================================
          // TELEGRAM
          // ====================================================

          await sendTelegramMessage(
            {
              chatId,
              text:
                telegramMessage,
            },
          )

          // ====================================================
          // MARCAR COMO ENVIADO
          // ====================================================

          await markReminderAsSent(
            reminder,
          )

          sent++

          console.log(
            `[REMINDER] Enviado ${reminderId} para user_id=${userId}.`,
          )
        } catch (
          error
        ) {
          const message =
            error instanceof
              Error
              ? error.message
              : String(
                  error,
                )

          console.error(
            `[REMINDER] Erro no lembrete ${reminderId || 'sem-id'} do usuário ${userId || 'sem-user'}:`,
            message,
          )

          errors.push(
            {
              id:
                reminderId,

              user_id:
                userId,

              error:
                message,
            },
          )
        }
      }

      // ========================================================
      // RESPONSE
      // ========================================================

      return Response.json(
        {
          ok:
            errors.length ===
            0,

          found:
            reminders.length,

          sent,

          skipped,

          failed:
            errors.length,

          errors,
        },
      )
    } catch (
      error
    ) {
      const message =
        error instanceof
          Error
          ? error.message
          : String(
              error,
            )

      console.error(
        '[SEND REMINDERS]',
        message,
      )

      return Response.json(
        {
          ok:
            false,

          error:
            message,
        },
        {
          status:
            500,
        },
      )
    }
  },
)
