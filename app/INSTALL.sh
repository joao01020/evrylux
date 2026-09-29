#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "Uso: ./INSTALL.sh /caminho/para/ghost-core/app"
  exit 1
fi

if [[ ! -d "$TARGET/lib" ]]; then
  echo "ERRO: pasta Flutter inválida: $TARGET"
  exit 1
fi

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$TARGET"

copy_file() {
  local rel="$1"
  mkdir -p "$(dirname "$rel")"
  cp "$SELF/$rel" "$rel"
}

while IFS= read -r rel; do
  [[ -z "$rel" ]] && continue
  copy_file "$rel"
done < "$SELF/MANIFEST.txt"

chmod +x scripts/check_phase4.sh

echo
echo "============================================================"
echo " EVRYLUX Web Fase 4 aplicada"
echo "============================================================"
echo "Web: somente Estudar + Financeiro."
echo "Desktop: módulos originais preservados."
echo "Financeiro Web usa a FinanceScreen real, Supabase e cache Web."
echo
echo "Valide com:"
echo "  ./scripts/check_phase4.sh"
echo
