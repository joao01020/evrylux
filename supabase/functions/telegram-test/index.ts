import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const TELEGRAM_BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN') ?? ''

const jsonHeaders = {
  'Content-Type': 'application/json; charset=utf-8',
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: jsonHeaders,
  })
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'Método não permitido.' }, 405)
  }

  const authorization = request.headers.get('Authorization')

  if (!authorization) {
    return json({ error: 'Sessão não encontrada.' }, 401)
  }

  if (!TELEGRAM_BOT_TOKEN) {
    return json({ error: 'TELEGRAM_BOT_TOKEN não configurado.' }, 500)
  }

  const caller = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: authorization,
      },
    },
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  })

  const { data: userData, error: userError } = await caller.auth.getUser()

  if (userError || !userData.user) {
    return json({ error: 'Sessão inválida.' }, 401)
  }

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  })

  const { data: connection, error: connectionError } = await admin
    .from('telegram_connections')
    .select('chat_id, enabled')
    .eq('user_id', userData.user.id)
    .eq('enabled', true)
    .maybeSingle()

  if (connectionError) {
    console.error('[TELEGRAM TEST]', connectionError)
    return json({ error: 'Não foi possível carregar sua conexão.' }, 500)
  }

  if (!connection?.chat_id) {
    return json({ error: 'Telegram ainda não conectado.' }, 409)
  }

  const response = await fetch(
    `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        chat_id: connection.chat_id,
        text: '✅ EVRYLUX conectado. Esta é uma mensagem de teste dos seus lembretes.',
      }),
    },
  )

  if (!response.ok) {
    const body = await response.text()
    console.error('[TELEGRAM TEST][SEND]', response.status, body)
    return json({ error: 'O Telegram recusou a mensagem de teste.' }, 502)
  }

  return json({ ok: true })
})
