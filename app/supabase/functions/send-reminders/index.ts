import { createClient } from 'npm:@supabase/supabase-js@2'

const SUPABASE_URL =
  Deno.env.get('SUPABASE_URL')

const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

const TELEGRAM_BOT_TOKEN =
  Deno.env.get('TELEGRAM_BOT_TOKEN')

const TELEGRAM_CHAT_ID =
  Deno.env.get('TELEGRAM_CHAT_ID')

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

if (!TELEGRAM_CHAT_ID) {
  throw new Error(
    'TELEGRAM_CHAT_ID não configurado.',
  )
}

const supabase = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY,
)

Deno.serve(
  async (
    _request,
  ) => {
    try {
      const now =
        new Date().toISOString()

      // ========================================================
      // BUSCAR LEMBRETES VENCIDOS
      // ========================================================

      const {
        data: reminders,
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

      if (reminderError) {
        throw reminderError
      }

      if (!reminders ||
          reminders.length ===
            0) {
        return Response.json(
          {
            ok:
              true,
            sent:
              0,
            message:
              'Nenhum lembrete pendente.',
          },
        )
      }

      let sent =
        0

      const errors:
        Array<
          {
            id:
              string
            error:
              string
          }
        > =
          []

      // ========================================================
      // ENVIAR LEMBRETES
      // ========================================================

      for (
        const reminder
        of reminders
      ) {
        try {
          const reminderDate =
            new Date(
              reminder.remind_at,
            )

          const formattedDate =
            new Intl.DateTimeFormat(
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
              reminderDate,
            )

          const title =
            String(
              reminder.title ??
                'Lembrete',
            ).trim()

          const message =
            String(
              reminder.message ??
                '',
            ).trim()

          const lines = [
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

          const telegramMessage =
            lines.join(
              '\n',
            )

          // ====================================================
          // TELEGRAM
          // ====================================================

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
                        TELEGRAM_CHAT_ID,

                      text:
                        telegramMessage,
                    },
                  ),
              },
            )

          const result =
            await response.json()

          if (
            !response.ok ||
            !result.ok
          ) {
            throw new Error(
              result.description ??
                'Erro ao enviar mensagem para o Telegram.',
            )
          }

          // ====================================================
          // MARCAR COMO ENVIADO
          // ====================================================

          const {
            error: updateError,
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

          if (
            updateError
          ) {
            throw updateError
          }

          sent++

          console.log(
            `[REMINDER] Enviado: ${reminder.id}`,
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
            `[REMINDER] Erro no lembrete ${reminder.id}:`,
            message,
          )

          errors.push(
            {
              id:
                String(
                  reminder.id,
                ),

              error:
                message,
            },
          )
        }
      }

      return Response.json(
        {
          ok:
            errors.length ===
            0,

          found:
            reminders.length,

          sent,

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