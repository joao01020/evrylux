#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(pwd)}"
cd "$ROOT"

if ! command -v supabase >/dev/null 2>&1; then
  echo "ERRO: Supabase CLI não encontrado."
  echo "Instale/configure o Supabase CLI antes de executar este script."
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERRO: curl não encontrado."
  exit 1
fi

if [[ ! -d supabase ]]; then
  echo "ERRO: pasta supabase não encontrada em: $ROOT"
  exit 1
fi

PROJECT_REF=""

if [[ -f supabase/.temp/project-ref ]]; then
  PROJECT_REF="$(tr -d '[:space:]' < supabase/.temp/project-ref)"
elif [[ -f supabase/.temp/linked-project.json ]] && command -v python3 >/dev/null 2>&1; then
  PROJECT_REF="$(python3 - <<'PY'
import json
from pathlib import Path
p=Path('supabase/.temp/linked-project.json')
try:
    data=json.loads(p.read_text())
    for key in ('project_ref','projectRef','ref'):
        value=data.get(key)
        if isinstance(value,str) and value.strip():
            print(value.strip())
            break
except Exception:
    pass
PY
)"
fi

if [[ -z "$PROJECT_REF" ]]; then
  read -r -p "Project Ref do Supabase: " PROJECT_REF
fi

PROJECT_REF="$(printf '%s' "$PROJECT_REF" | tr -d '[:space:]')"

if [[ -z "$PROJECT_REF" ]]; then
  echo "ERRO: Project Ref é obrigatório."
  exit 1
fi

read -r -p "Username do bot Telegram (sem @): " BOT_USERNAME
BOT_USERNAME="${BOT_USERNAME#@}"

if [[ -z "$BOT_USERNAME" ]]; then
  echo "ERRO: username do bot é obrigatório."
  exit 1
fi

read -r -s -p "Token do bot Telegram: " BOT_TOKEN
echo

if [[ -z "$BOT_TOKEN" ]]; then
  echo "ERRO: token do bot é obrigatório."
  exit 1
fi

if command -v openssl >/dev/null 2>&1; then
  WEBHOOK_SECRET="$(openssl rand -hex 24)"
elif command -v python3 >/dev/null 2>&1; then
  WEBHOOK_SECRET="$(python3 - <<'PY'
import secrets
print(secrets.token_hex(24))
PY
)"
else
  echo "ERRO: openssl ou python3 é necessário para gerar o segredo do webhook."
  exit 1
fi

echo
echo "[1/5] Aplicando migration..."
supabase db push

echo
echo "[2/5] Salvando secrets..."
supabase secrets set \
  TELEGRAM_BOT_TOKEN="$BOT_TOKEN" \
  TELEGRAM_BOT_USERNAME="$BOT_USERNAME" \
  TELEGRAM_WEBHOOK_SECRET="$WEBHOOK_SECRET"

echo
echo "[3/5] Publicando Edge Functions..."
supabase functions deploy telegram-link
supabase functions deploy telegram-test
supabase functions deploy telegram-webhook --no-verify-jwt

WEBHOOK_URL="https://${PROJECT_REF}.supabase.co/functions/v1/telegram-webhook"

echo
echo "[4/5] Configurando webhook do Telegram..."
RESULT="$(curl -fsS -X POST \
  "https://api.telegram.org/bot${BOT_TOKEN}/setWebhook" \
  --data-urlencode "url=${WEBHOOK_URL}" \
  --data-urlencode "secret_token=${WEBHOOK_SECRET}" \
  --data-urlencode 'allowed_updates=["message"]')"

echo "$RESULT"

echo
echo "[5/5] Conferindo webhook..."
curl -fsS \
  "https://api.telegram.org/bot${BOT_TOKEN}/getWebhookInfo"
echo

echo
echo "=========================================="
echo "TELEGRAM EVRYLUX CONFIGURADO"
echo "=========================================="
echo "Bot: @${BOT_USERNAME}"
echo "Webhook: ${WEBHOOK_URL}"
echo
echo "Agora abra o app e teste:"
echo "Configurações > Telegram > Conectar Telegram"
