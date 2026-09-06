import { createClient } from '@supabase/supabase-js'

type LinkRequestRow = {
  id: string
  user_id: string
  token_hash: string
  expires_at: string
  consumed_at: string | null
}

const SUPABASE_URL =
  Deno.env.get('SUPABASE_URL') ?? ''

const SUPABASE_ANON_KEY =
  Deno.env.get('SUPABASE_ANON_KEY') ?? ''

const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const TELEGRAM_BOT_USERNAME =
  Deno.env.get('TELEGRAM_BOT_USERNAME') ?? ''

const JSON_HEADERS = {
  'Content-Type': 'application/json; charset=utf-8',
}

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

function bytesToHex(
  bytes: Uint8Array,
): string {
  return Array
    .from(bytes)
    .map(
      (byte) => byte
        .toString(16)
        .padStart(2, '0'),
    )
    .join('')
}

function createRandomToken(): string {
  const bytes =
    new Uint8Array(24)

  crypto.getRandomValues(
    bytes,
  )

  return bytesToHex(
    bytes,
  )
}

async function sha256(
  value: string,
): Promise<string> {
  const encoded =
    new TextEncoder()
      .encode(value)

  const digest =
    await crypto.subtle.digest(
      'SHA-256',
      encoded,
    )

  return bytesToHex(
    new Uint8Array(
      digest,
    ),
  )
}

Deno.serve(
  async (
    request: Request,
  ): Promise<Response> => {
    try {
      if (request.method !== 'POST') {
        return jsonResponse(
          {
            error:
              'Método não permitido.',
          },
          405,
        )
      }

      if (
        !SUPABASE_URL ||
        !SUPABASE_ANON_KEY ||
        !SUPABASE_SERVICE_ROLE_KEY
      ) {
        console.error(
          '[TELEGRAM LINK] '
            + 'Variáveis obrigatórias do Supabase ausentes.',
        )

        return jsonResponse(
          {
            error:
              'Serviço temporariamente indisponível.',
          },
          500,
        )
      }

      if (!TELEGRAM_BOT_USERNAME) {
        console.error(
          '[TELEGRAM LINK] '
            + 'TELEGRAM_BOT_USERNAME não configurado.',
        )

        return jsonResponse(
          {
            error:
              'Bot do Telegram não configurado.',
          },
          500,
        )
      }

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

      const caller =
        createClient(
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
          '[TELEGRAM LINK][AUTH]',
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

      const admin =
        createClient(
          SUPABASE_URL,
          SUPABASE_SERVICE_ROLE_KEY,
          {
            auth: {
              persistSession: false,
              autoRefreshToken: false,
            },
          },
        )

      // Remove solicitações antigas não consumidas.
      const {
        error: cleanupError,
      } =
        await admin
          .from(
            'telegram_link_requests',
          )
          .delete()
          .eq(
            'user_id',
            userId,
          )
          .is(
            'consumed_at',
            null,
          )

      if (cleanupError != null) {
        console.error(
          '[TELEGRAM LINK][CLEANUP]',
          cleanupError,
        )

        return jsonResponse(
          {
            error:
              'Não foi possível preparar uma nova conexão.',
          },
          500,
        )
      }

      const token =
        createRandomToken()

      const tokenHash =
        await sha256(
          token,
        )

      const expiresAt =
        new Date(
          Date.now() +
            (10 * 60 * 1000),
        ).toISOString()

      const {
        error: insertError,
      } =
        await admin
          .from(
            'telegram_link_requests',
          )
          .insert(
            {
              user_id: userId,
              token_hash: tokenHash,
              expires_at: expiresAt,
              consumed_at: null,
            },
          )

      if (insertError != null) {
        console.error(
          '[TELEGRAM LINK][INSERT]',
          insertError,
        )

        return jsonResponse(
          {
            error:
              'Não foi possível criar a conexão com o Telegram.',
          },
          500,
        )
      }

      const username =
        TELEGRAM_BOT_USERNAME
          .replace(
            /^@/,
            '',
          )
          .trim()

      if (username.length === 0) {
        return jsonResponse(
          {
            error:
              'Username do bot inválido.',
          },
          500,
        )
      }

      const url =
        `https://t.me/${username}?start=${token}`

      return jsonResponse(
        {
          ok: true,
          url,
          expires_at:
            expiresAt,
        },
      )
    } catch (error) {
      console.error(
        '[TELEGRAM LINK][UNHANDLED]',
        error,
      )

      return jsonResponse(
        {
          error:
            'Não foi possível iniciar a conexão com o Telegram.',
        },
        500,
      )
    }
  },
)