import { createClient } from '@supabase/supabase-js'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

if (!SUPABASE_URL) {
  throw new Error('SUPABASE_URL não configurada.')
}

if (!SUPABASE_ANON_KEY) {
  throw new Error('SUPABASE_ANON_KEY não configurada.')
}

if (!SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error('SUPABASE_SERVICE_ROLE_KEY não configurada.')
}

const jsonHeaders = {
  'Content-Type': 'application/json',
}

function jsonResponse(
  status: number,
  body: Record<string, unknown>,
) {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: jsonHeaders,
    },
  )
}

async function deleteStoragePrefix(
  admin: ReturnType<typeof createClient>,
  bucket: string,
  prefix: string,
) {
  const paths: string[] = []

  async function walk(currentPrefix: string) {
    let offset = 0

    while (true) {
      const { data, error } = await admin.storage
        .from(bucket)
        .list(currentPrefix, {
          limit: 100,
          offset,
        })

      if (error) {
        // Bucket inexistente ou sem conteúdo: não bloqueia a limpeza
        // dos demais dados.
        return
      }

      if (!data || data.length === 0) {
        return
      }

      for (const item of data) {
        const itemPath = currentPrefix.length > 0
          ? `${currentPrefix}/${item.name}`
          : item.name

        if (item.id) {
          paths.push(itemPath)
        } else {
          await walk(itemPath)
        }
      }

      if (data.length < 100) {
        return
      }

      offset += data.length
    }
  }

  await walk(prefix)

  for (let index = 0; index < paths.length; index += 100) {
    const chunk = paths.slice(index, index + 100)

    if (chunk.length === 0) {
      continue
    }

    const { error } = await admin.storage
      .from(bucket)
      .remove(chunk)

    if (error) {
      throw error
    }
  }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return jsonResponse(405, {
      ok: false,
      error: 'Método não permitido.',
    })
  }

  const authorization = request.headers.get('Authorization')

  if (!authorization) {
    return jsonResponse(401, {
      ok: false,
      error: 'Autorização ausente.',
    })
  }

  let body: { mode?: string }

  try {
    body = await request.json()
  } catch (_) {
    return jsonResponse(400, {
      ok: false,
      error: 'JSON inválido.',
    })
  }

  const mode = body.mode?.trim().toLowerCase()

  if (mode !== 'data' && mode !== 'account') {
    return jsonResponse(400, {
      ok: false,
      error: 'Modo inválido.',
    })
  }

  const caller = createClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY,
    {
      global: {
        headers: {
          Authorization: authorization,
        },
      },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    },
  )

  const { data: userData, error: userError } = await caller.auth.getUser()

  if (userError || !userData.user) {
    return jsonResponse(401, {
      ok: false,
      error: 'Sessão inválida.',
    })
  }

  const user = userData.user

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

  try {
    // Storage é removido pela API oficial, não por DELETE direto em
    // storage.objects.
    await deleteStoragePrefix(admin, 'board-files', user.id)
    await deleteStoragePrefix(admin, 'routine-images', user.id)

    const { error: cleanupError } = await admin.rpc(
      'delete_evrylux_user_data_for',
      {
        p_user_id: user.id,
      },
    )

    if (cleanupError) {
      throw cleanupError
    }

    if (mode === 'data') {
      const { error: metadataError } = await admin.auth.admin.updateUserById(
        user.id,
        {
          user_metadata: {},
        },
      )

      if (metadataError) {
        throw metadataError
      }

      return jsonResponse(200, {
        ok: true,
        mode,
      })
    }

    const { error: deleteUserError } = await admin.auth.admin.deleteUser(
      user.id,
    )

    if (deleteUserError) {
      throw deleteUserError
    }

    return jsonResponse(200, {
      ok: true,
      mode,
    })
  } catch (error) {
    console.error('[ACCOUNT CLEANUP]', error)

    return jsonResponse(500, {
      ok: false,
      error: 'Não foi possível concluir a exclusão.',
    })
  }
})
