#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== REMOTE-FIRST REPOSITORY ==="
grep -n -A 55 "Future<Map<String, dynamic>> load()" \
  lib/finance/data/repository/finance_repository_web.dart

echo
echo "=== WEB FIRST LOAD ==="
grep -n -A 45 "Future<void> loadCached" \
  lib/finance/controllers/finance_screen_controller.dart

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/finance/data/repository/finance_repository_web.dart \
  lib/finance/controllers/finance_screen_controller.dart \
  lib/finance/screen/finance_screen.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK."
echo "Ao abrir Financeiro no Web, procure no console por:"
echo "  [FINANCE][WEB] REMOTE LOAD ..."
echo "ou:"
echo "  [FINANCE][WEB] REMOTE REFRESH ..."
