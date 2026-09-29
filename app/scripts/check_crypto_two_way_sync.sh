#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

grep -n "supabase_flutter.*hide LocalStorage"   lib/finance/data/repository/crypto/crypto_repository.dart
grep -n "_cloudTable" lib/finance/data/repository/crypto/crypto_repository.dart
grep -n -A 90 "_syncWithCloud" lib/finance/data/repository/crypto/crypto_repository.dart | head -130
grep -n -A 70 "_syncNativeCryptoBalancesToFinanceData" lib/finance/controllers/finance_screen_controller.dart | head -100

test -f supabase/migrations/202609280009_finance_crypto_two_way_sync.sql

flutter analyze   lib/finance/data/repository/crypto/crypto_repository.dart   lib/finance/controllers/finance_screen_controller.dart   lib/finance/widgets/crypto/crypto_dialog.dart   lib/finance/screen/finance_screen.dart

./scripts/build_web.sh

echo "OK: two-way sync validado."
