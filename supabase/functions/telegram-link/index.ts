import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const TELEGRAM_BOT_USERNAME = (Deno.env.get('TELEGRAM_BOT_USERNAME') ?? '')
  .trim()
  .replace(/^@/, '')

const jsonHeaders = {
  'Content-Type': 'application/json; charset=utf-8',
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: jsonHeaders,
  })
}

function base64Url(bytes: Uint8Array) {
  let binary = ''

  for (const byte of bytes) {
    binary += String.fromCharCode(byte)
  }

  return btoa(binary)
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '')
}

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', bytes)

  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return json({ error: 'Método não permitido.' }, 405)
  }

  if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
    return json({ error: 'Supabase não configurado na função.' }, 500)
  }

  if (!TELEGRAM_BOT_USERNAME) {
    return json({ error: 'TELEGRAM_BOT_USERNAME não configurado.' }, 500)
  }

  const authorization = request.headers.get('Authorization')

  if (!authorization) {
    return json({ error: 'Sessão não encontrada.' }, 401)
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

  const userId = userData.user.id

  await admin
    .from('telegram_link_requests')
    .delete()
    .eq('user_id', userId)
    .is('consumed_at', null)

  const tokenBytes = new Uint8Array(24)
  crypto.getRandomValues(tokenBytes)

  const token = base64Url(tokenBytes)
  const tokenHash = await sha256(token)
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString()

  const { error: insertError } = await admin
    .from('telegram_link_requests')
    .insert({
      user_id: userId,
      token_hash: tokenHash,
      expires_at: expiresAt,
    })

  if (insertError) {
    console.error('[TELEGRAM LINK]', insertError)
    return json({ error: 'Não foi possível preparar a conexão.' }, 500)
  }

  return json({
    ok: true,
    url: `https://t.me/${TELEGRAM_BOT_USERNAME}?start=${token}`,
    expires_at: expiresAt,
  })
})
