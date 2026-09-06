import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const jsonHeaders = {
  'Content-Type': 'application/json; charset=utf-8',
}

function json(
  data: unknown,
  status = 200,
) {
  return new Response(
    JSON.stringify(data),
    {
      status,
      headers: jsonHeaders,
    },
  )
}

Deno.serve(
  async (
    request,
  ) => {
    // ============================================================
    // METHOD
    // ============================================================

    if (request.method != 'POST') {
      return json(
        {
          error: 'Método não permitido.',
        },
        405,
      )
    }

    // ============================================================
    // CONFIG
    // ============================================================

    if (
      !SUPABASE_URL ||
      !SUPABASE_ANON_KEY ||
      !SUPABASE_SERVICE_ROLE_KEY
    ) {
      return json(
        {
          error: 'Supabase não configurado na função.',
        },
        500,
      )
    }

    // ============================================================
    // AUTHORIZATION
    // ============================================================

    const authorization =
      request.headers.get(
        'Authorization',
      )

    if (!authorization) {
      return json(
        {
          error: 'Sessão não encontrada.',
        },
        401,
      )
    }

    // ============================================================
    // CLIENT DO USUÁRIO
    // ============================================================

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

    // ============================================================
    // VALIDAR USUÁRIO
    // ============================================================

    const {
      data: userData,
      error: userError,
    } =
      await caller.auth.getUser()

    if (
      userError ||
      !userData.user
    ) {
      return json(
        {
          error: 'Sessão inválida.',
        },
        401,
      )
    }

    // ============================================================
    // ADMIN CLIENT
    // ============================================================

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

    // ============================================================
    // DELETE CONNECTION
    // ============================================================

    const {
      error: deleteError,
    } =
      await admin
        .from(
          'telegram_connections',
        )
        .delete()
        .eq(
          'user_id',
          userData.user.id,
        )

    if (deleteError) {
      console.error(
        '[TELEGRAM DISCONNECT]',
        deleteError,
      )

      return json(
        {
          error:
            'Não foi possível desconectar o Telegram.',
        },
        500,
      )
    }

    // ============================================================
    // INVALIDAR LINKS PENDENTES
    // ============================================================

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
          userData.user.id,
        )
        .is(
          'consumed_at',
          null,
        )

    if (cleanupError) {
      // Não falhamos o disconnect por causa disso.
      // A conexão principal já foi removida.
      console.error(
        '[TELEGRAM DISCONNECT][CLEANUP]',
        cleanupError,
      )
    }

    // ============================================================
    // RESPONSE
    // ============================================================

    return json(
      {
        ok: true,
      },
    )
  },
)