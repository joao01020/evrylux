#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FILES=(
  lib/welcome/welcome_screen_web.dart
  lib/app/widgets/web_global_header_shell.dart
  lib/app/services/web_sync_status_controller.dart
  lib/app/services/web_update_notification_controller.dart
)
dart format "${FILES[@]}"
echo "=== HOME ==="
grep -n "name: 'Estudar'" lib/welcome/welcome_screen_web.dart
grep -n "name: 'Financeiro'" lib/welcome/welcome_screen_web.dart
if grep -nE "name: '(Treinar|Rotina|Evolução)'" lib/welcome/welcome_screen_web.dart; then
  echo "ERRO: módulo extra encontrado na Home Web." >&2; exit 1
fi
grep -n "height: veryCompact" lib/welcome/welcome_screen_web.dart
echo "=== SINO ==="
grep -n "class _WebNotificationBell" lib/app/widgets/web_global_header_shell.dart
if grep -n -A 70 "class _WebNotificationBell" lib/app/widgets/web_global_header_shell.dart | grep -q "InkWell"; then
  echo "ERRO: sino ainda usa InkWell/círculo de interação." >&2; exit 1
fi
echo "=== ANALYZE ==="
flutter analyze "${FILES[@]}"
echo "=== BUILD WEB ==="
./scripts/build_web.sh
echo "OK."
