import { createClient } from '@supabase/supabase-js'

// ============================================================
// TYPES
// ============================================================

type TelegramConnectionRow = {
  user_id: string
  chat_id: string
  username: string | null
  first_name: string | null
  enabled: boolean
}

type TelegramApiResponse = {
  ok?: boolean
  description?: string
  error_code?: number
}

// ============================================================
// ENV
// ============================================================

const SUPABASE_URL =
  Deno.env.get('SUPABASE_URL') ?? ''

const SUPABASE_ANON_KEY =
  Deno.env.get('SUPABASE_ANON_KEY') ?? ''

const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const TELEGRAM_BOT_TOKEN =
  Deno.env.get('TELEGRAM_BOT_TOKEN') ?? ''

// ============================================================
// HEADERS
// ============================================================

const JSON_HEADERS = {
  'Content-Type': 'application/json; charset=utf-8',
}

// ============================================================
// RESPONSE
// ============================================================

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: JSON_HEADERS,
    },
  )
}

// ============================================================
// HTML ESCAPE
// ============================================================

function escapeHtml(
  value: string,
): string {
  return value
    .replaceAll(
      '&',
      '&amp;',
    )
    .replaceAll(
      '<',
      '&lt;',
    )
    .replaceAll(
      '>',
      '&gt;',
    )
    .replaceAll(
      '"',
      '&quot;',
    )
    .replaceAll(
      "'",
      '&#039;',
    )
}

// ============================================================
// SEND TELEGRAM MESSAGE
// ============================================================

async function sendTelegramMessage({
  chatId,
  text,
}: {
  chatId: string
  text: string
}): Promise<void> {
  if (!TELEGRAM_BOT_TOKEN) {
    throw new Error(
      'TELEGRAM_BOT_TOKEN não configurado.',
    )
  }

  const response = await fetch(
    `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
    {
      method: 'POST',

      headers: {
        'Content-Type': 'application/json',
      },

      body: JSON.stringify(
        {
          chat_id: chatId,
          text,
          parse_mode: 'HTML',
          disable_web_page_preview: true,
        },
      ),
    },
  )

  let data: TelegramApiResponse | null = null

  try {
    data =
      await response.json() as TelegramApiResponse
  } catch {
    data = null
  }

  if (
    !response.ok ||
    data?.ok !== true
  ) {
    console.error(
      '[TELEGRAM TEST][TELEGRAM API]',
      {
        status: response.status,
        errorCode:
          data?.error_code,
        description:
          data?.description,
      },
    )

    throw new Error(
      data?.description ??
        'O Telegram recusou o envio da mensagem.',
    )
  }
}

// ============================================================
// MAIN
// ============================================================

Deno.serve(
  async (
    request: Request,
  ): Promise<Response> => {
    try {
      // ========================================================
      // METHOD
      // ========================================================

      if (request.method !== 'POST') {
        return jsonResponse(
          {
            error:
              'Método não permitido.',
          },
          405,
        )
      }

      // ========================================================
      // ENV VALIDATION
      // ========================================================

      if (
        !SUPABASE_URL ||
        !SUPABASE_ANON_KEY ||
        !SUPABASE_SERVICE_ROLE_KEY
      ) {
        console.error(
          '[TELEGRAM TEST] '
            + 'Variáveis obrigatórias do Supabase não configuradas.',
        )

        return jsonResponse(
          {
            error:
              'Serviço temporariamente indisponível.',
          },
          500,
        )
      }

      if (!TELEGRAM_BOT_TOKEN) {
        console.error(
          '[TELEGRAM TEST] '
            + 'TELEGRAM_BOT_TOKEN não configurado.',
        )

        return jsonResponse(
          {
            error:
              'Bot do Telegram não configurado.',
          },
          500,
        )
      }

      // ========================================================
      // AUTHORIZATION
      // ========================================================

      const authorization =
        request.headers.get(
          'Authorization',
        )

      if (
        authorization == null ||
        authorization.trim().length === 0
      ) {
        return jsonResponse(
          {
            error:
              'Sessão não encontrada.',
          },
          401,
        )
      }

      // ========================================================
      // CALLER CLIENT
      // ========================================================

      const caller = createClient(
        SUPABASE_URL,
        SUPABASE_ANON_KEY,
        {
          global: {
            headers: {
              Authorization:
                authorization,
            },
          },

          auth: {
            persistSession: false,
            autoRefreshToken: false,
          },
        },
      )

      // ========================================================
      // VALIDATE USER
      // ========================================================

      const {
        data: userData,
        error: userError,
      } =
        await caller.auth.getUser()

      const user =
        userData.user

      if (
        userError != null ||
        user == null
      ) {
        console.error(
          '[TELEGRAM TEST][AUTH]',
          userError,
        )

        return jsonResponse(
          {
            error:
              'Sessão inválida ou expirada.',
          },
          401,
        )
      }

      const userId =
        user.id.trim()

      if (userId.length === 0) {
        return jsonResponse(
          {
            error:
              'Usuário inválido.',
          },
          401,
        )
      }

      // ========================================================
      // ADMIN CLIENT
      // ========================================================

      const admin = createClient(
        SUPABASE_URL,
        SUPABASE_SERVICE_ROLE_KEY,
        {
          auth: {
            persistSession: false,
            autoRefreshToken: false,
          },
        },
      )

      // ========================================================
      // LOAD CONNECTION
      // ========================================================

      const {
        data,
        error: connectionError,
      } =
        await admin
          .from(
            'telegram_connections',
          )
          .select(
            'user_id, chat_id, username, first_name, enabled',
          )
          .eq(
            'user_id',
            userId,
          )
          .maybeSingle()

      if (connectionError != null) {
        console.error(
          '[TELEGRAM TEST][CONNECTION]',
          connectionError,
        )

        return jsonResponse(
          {
            error:
              'Não foi possível carregar sua conexão com o Telegram.',
          },
          500,
        )
      }

      const connection =
        data as TelegramConnectionRow | null

      if (connection == null) {
        return jsonResponse(
          {
            error:
              'Seu Telegram ainda não está conectado.',
          },
          409,
        )
      }

      if (connection.enabled !== true) {
        return jsonResponse(
          {
            error:
              'Sua conexão com o Telegram está desativada.',
          },
          409,
        )
      }

      // ========================================================
      // CHAT ID
      // ========================================================

      const chatId =
        String(
          connection.chat_id ?? '',
        ).trim()

      if (chatId.length === 0) {
        console.error(
          '[TELEGRAM TEST] '
            + 'Conexão encontrada sem chat_id.',
          {
            userId,
          },
        )

        return jsonResponse(
          {
            error:
              'Sua conexão com o Telegram está incompleta.',
          },
          409,
        )
      }

      // ========================================================
      // DISPLAY NAME
      // ========================================================

      const firstName =
        String(
          connection.first_name ?? '',
        ).trim()

      // ========================================================
      // MESSAGE
      // ========================================================

      const messageLines: string[] = [
        '✅ <b>EVRYLUX conectado</b>',
        '',
      ]

      if (firstName.length > 0) {
        messageLines.push(
          `Olá, ${escapeHtml(firstName)}.`,
          '',
        )
      }

      messageLines.push(
        'Esta é uma mensagem de teste.',
        '',
        'Se você recebeu esta mensagem, '
          + 'seu Telegram está conectado ao EVRYLUX '
          + 'e poderá receber seus lembretes.',
      )

      const message =
        messageLines.join(
          '\n',
        )

      // ========================================================
      // SEND
      // ========================================================

      await sendTelegramMessage(
        {
          chatId,
          text: message,
        },
      )

      // ========================================================
      // SUCCESS
      // ========================================================

      return jsonResponse(
        {
          ok: true,
        },
      )
    } catch (error) {
      console.error(
        '[TELEGRAM TEST][UNHANDLED]',
        error,
      )

      return jsonResponse(
        {
          error:
            'Não foi possível enviar a mensagem de teste.',
        },
        500,
      )
    }
  },
)