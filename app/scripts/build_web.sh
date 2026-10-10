#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f .env ]]; then
  echo "Carregando variáveis de app/.env..."

  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
else
  echo "app/.env não encontrado."
  echo "Usando variáveis fornecidas pelo ambiente de build."
fi

: "${SUPABASE_URL:?SUPABASE_URL não definida}"
: "${SUPABASE_PUBLISHABLE_KEY:?SUPABASE_PUBLISHABLE_KEY não definida}"

flutter build web --release \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY"

echo
echo "EVRYLUX Web gerado em: $ROOT/build/web"
