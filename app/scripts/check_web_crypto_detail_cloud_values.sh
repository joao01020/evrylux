#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
echo '=== WEB DIALOG ==='
grep -n -A 38 "if (kIsWeb)" lib/finance/widgets/crypto/crypto_dialog.dart | head -70
echo '=== COST BASIS CLOUD ==='
grep -n -A 70 "_loadWebCryptoInvestedFromCloud" lib/finance/controllers/finance_screen_controller.dart | head -110
echo '=== MIGRATION ==='
grep -n "bitcoin_invested" supabase/migrations/202609280007_finance_crypto_invested_by_asset.sql
echo '=== ANALYZE ==='
flutter analyze lib/finance/controllers/finance_screen_controller.dart lib/finance/widgets/crypto/crypto_dialog.dart lib/finance/screen/finance_screen.dart
echo '=== BUILD WEB ==='
./scripts/build_web.sh
echo 'OK'
