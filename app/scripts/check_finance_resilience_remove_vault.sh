#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== CACHE COM TIMESTAMP ==="
grep -RIn \
  "loadPriceSnapshot\\|prices.brl.updated_at\\|updated_at" \
  lib/finance/data/cache/finance_cache_store_web.dart \
  lib/finance/data/cache/finance_cache_store_native.dart

echo
echo "=== STALE-WHILE-REVALIDATE ==="
grep -RIn \
  "staleWhileRevalidateFor\\|cache-stale\\|background-refresh" \
  lib/finance/services/crypto

echo
echo "=== PROTEÇÃO CONTRA ZERO ==="
grep -RIn \
  "parsed > 0\\|_isValidPrice\\|preservando último cache válido" \
  lib/finance/services/crypto/crypto_price_service.dart

echo
echo "=== LOGS ==="
grep -RIn \
  "\\[FINANCE\\]\\[PRICE\\]\\|\\[FINANCE\\]\\[PORTFOLIO\\]" \
  lib/finance/services/crypto/crypto_price_service.dart \
  lib/finance/controllers/finance_screen_controller.dart

echo
echo "=== COFRE REMOVIDO ==="
if grep -RIn \
  "onVault\\|openVault\\|VaultScreen\\|vault_screen\\|tooltip: 'Cofre'\\|Icons.key_outlined" \
  lib/finance 2>/dev/null; then
  echo "ERRO: ainda existe referência à página Cofre."
  exit 1
else
  echo "OK: ícone, navegação e página Cofre removidos."
fi

if [[ -e lib/finance/vault/vault_screen.dart ]]; then
  echo "ERRO: vault_screen.dart ainda existe."
  exit 1
fi

echo
echo "=== ESCOPO: HEADER/ROTINA/BRAIN NÃO DEVEM SER TOCADOS PELO PATCH ==="
git status --short -- \
  lib/app/app_web.dart \
  lib/app/widgets/web_global_header_shell.dart \
  lib/routine \
  lib/study \
  lib/profile || true

echo
echo "OK."
