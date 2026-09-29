#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILE="lib/finance/controllers/finance_screen_controller.dart"

dart format "$FILE"

echo "=== WEB NÃO USA CARTEIRA LOCAL ==="
grep -n -A 18 "Future<void> _loadCryptoPrices" "$FILE"
grep -n -A 18 "Future<void> refreshCryptoBalances" "$FILE"

echo
echo "=== DESKTOP PUBLICA QUANTIDADES CONSOLIDADAS ==="
grep -n -A 55 "_syncNativeCryptoBalancesToFinanceData" "$FILE"

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/finance/controllers/finance_screen_controller.dart \
  lib/finance/data/repository/finance_repository_web.dart \
  lib/finance/runtime/finance_runtime_web.dart \
  lib/finance/screen/finance_screen.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: fluxo Finance Desktop -> finance_data -> Web preparado."
