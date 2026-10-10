#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

FLUTTER_DIR="$HOME/flutter"

echo "===== COMMIT DO BUILD ====="
git rev-parse HEAD
echo

echo "===== Preparando Flutter ====="

if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  git clone \
    --depth 1 \
    --branch stable \
    https://github.com/flutter/flutter.git \
    "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version

echo
echo "===== Dependências ====="

cd "$REPO_ROOT/app"

flutter pub get

echo
echo "===== Verificando variáveis ====="
if [[ -n "${SUPABASE_URL:-}" ]]; then
  echo "SUPABASE_URL=OK"
else
  echo "SUPABASE_URL=AUSENTE"
fi

if [[ -n "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  echo "SUPABASE_PUBLISHABLE_KEY=OK"
else
  echo "SUPABASE_PUBLISHABLE_KEY=AUSENTE"
fi

echo
echo "===== Criando .env temporário para o Flutter ====="
cat > app/.env <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}
EOF
echo

echo "===== Build EVRYLUX Web ====="

chmod +x scripts/build_web.sh
./scripts/build_web.sh

echo
echo "===== Build concluído ====="
