import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const TELEGRAM_BOT_TOKEN = Deno.env.get('TELEGRAM_BOT_TOKEN') ?? ''
const TELEGRAM_WEBHOOK_SECRET = Deno.env.get('TELEGRAM_WEBHOOK_SECRET') ?? ''

const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
})

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', bytes)

  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('')
}

async function sendMessage(chatId: string, text: string) {
  if (!TELEGRAM_BOT_TOKEN) {
    throw new Error('TELEGRAM_BOT_TOKEN não configurado.')
  }

  const response = await fetch(
    `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        chat_id: chatId,
        text,
      }),
    },
  )

  if (!response.ok) {
    const body = await response.text()
    throw new Error(`Telegram sendMessage falhou: ${response.status} ${body}`)
  }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response('ok')
  }

  if (TELEGRAM_WEBHOOK_SECRET) {
    const received = request.headers.get('X-Telegram-Bot-Api-Secret-Token') ?? ''

    if (received !== TELEGRAM_WEBHOOK_SECRET) {
      return new Response('unauthorized', { status: 401 })
    }
  }

  try {
    const update = await request.json()
    const message = update?.message
    const text = message?.text?.toString().trim() ?? ''
    const chatId = message?.chat?.id?.toString() ?? ''

    if (!chatId || !text.startsWith('/start')) {
      return new Response('ok')
    }

    const parts = text.split(/\s+/)
    const token = parts.length > 1 ? parts[1].trim() : ''

    if (!token) {
      await sendMessage(
        chatId,
        'Abra a conexão pelo EVRYLUX para vincular este Telegram à sua conta.',
      )

      return new Response('ok')
    }

    const tokenHash = await sha256(token)
    const now = new Date().toISOString()

    const { data: linkRequest, error: requestError } = await admin
      .from('telegram_link_requests')
      .select('id, user_id, expires_at, consumed_at')
      .eq('token_hash', tokenHash)
      .is('consumed_at', null)
      .gt('expires_at', now)
      .maybeSingle()

    if (requestError) {
      console.error('[TELEGRAM WEBHOOK][LINK]', requestError)
      return new Response('ok')
    }

    if (!linkRequest) {
      await sendMessage(
        chatId,
        'Este link expirou ou já foi utilizado. Gere um novo link no EVRYLUX.',
      )

      return new Response('ok')
    }

    const userId = linkRequest.user_id.toString()
    const username = message?.from?.username?.toString() ?? null
    const firstName = message?.from?.first_name?.toString() ?? null

    // Um mesmo chat privado pertence a apenas uma conta EVRYLUX por vez.
    await admin
      .from('telegram_connections')
      .delete()
      .eq('chat_id', chatId)
      .neq('user_id', userId)

    const { error: connectionError } = await admin
      .from('telegram_connections')
      .upsert(
        {
          user_id: userId,
          chat_id: chatId,
          username,
          first_name: firstName,
          enabled: true,
          connected_at: now,
          updated_at: now,
        },
        {
          onConflict: 'user_id',
        },
      )

    if (connectionError) {
      console.error('[TELEGRAM WEBHOOK][CONNECTION]', connectionError)
      await sendMessage(
        chatId,
        'Não foi possível concluir a conexão agora. Tente novamente pelo EVRYLUX.',
      )

      return new Response('ok')
    }

    await admin
      .from('telegram_link_requests')
      .update({
        consumed_at: now,
      })
      .eq('id', linkRequest.id)

    await sendMessage(
      chatId,
      '✅ Telegram conectado ao EVRYLUX. Seus lembretes poderão ser enviados para esta conversa.',
    )
  } catch (error) {
    console.error('[TELEGRAM WEBHOOK]', error)
  }

  return new Response('ok')
})
