#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== WEB PRESERVA CARTEIRA REMOTA ==="
grep -n -A70 -B8 \
  "O FinanceScreenController já hidratou" \
  lib/finance/controllers/crypto/crypto_controller.dart

echo
echo "=== MODAL TEM FALLBACK QUANTIDADE x PREÇO ==="
grep -n -A25 -B5 \
  "double get currentValue" \
  lib/finance/widgets/crypto/crypto_dialog.dart

echo
echo "=== ESCOPO ==="
git status --short -- \
  lib/finance/controllers/crypto/crypto_controller.dart \
  lib/finance/widgets/crypto/crypto_dialog.dart

echo
echo "OK."
