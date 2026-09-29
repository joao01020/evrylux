#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

test -f supabase/migrations/202609280008_finance_crypto_transactions_cloud.sql
grep -n "finance_crypto_transactions" supabase/migrations/202609280008_finance_crypto_transactions_cloud.sql
grep -n -A 110 "_syncNativeCryptoBalancesToFinanceData" lib/finance/controllers/finance_screen_controller.dart | head -150
grep -n -A 100 "Future.*load" lib/finance/widgets/crypto/crypto_dialog.dart | head -150
grep -n -A 30 "double get totalInvested" lib/finance/widgets/crypto/crypto_dialog.dart

flutter analyze   lib/finance/controllers/finance_screen_controller.dart   lib/finance/widgets/crypto/crypto_dialog.dart   lib/finance/screen/finance_screen.dart

./scripts/build_web.sh
echo "OK: sync de investido/histórico preparado."
