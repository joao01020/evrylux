#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILE="lib/finance/controllers/finance_screen_controller.dart"

dart format "$FILE"

echo "=== BACKFILL DIRETO ==="
grep -n -A 85 "_syncNativeCryptoBalancesToFinanceData" "$FILE"

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/finance/controllers/finance_screen_controller.dart \
  lib/finance/data/repository/finance_repository_native.dart \
  lib/finance/data/repository/finance_repository_web.dart \
  lib/finance/screen/finance_screen.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: backfill direto preparado."
