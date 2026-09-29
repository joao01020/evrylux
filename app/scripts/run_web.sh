#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "ERRO: .env não encontrado em $ROOT" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

: "${SUPABASE_URL:?SUPABASE_URL não definida no .env}"
: "${SUPABASE_PUBLISHABLE_KEY:?SUPABASE_PUBLISHABLE_KEY não definida no .env}"

# Porta fixa é importante no desenvolvimento Web:
# browser storage é isolado por origem (host + porta).
# Sem porta fixa, cada `flutter run` pode criar uma origem diferente e,
# consequentemente, uma nova identidade/fingerprint do Brain.
WEB_PORT="${EVRYLUX_WEB_PORT:-7357}"

flutter run -d chrome \
  --web-port="$WEB_PORT" \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY"
