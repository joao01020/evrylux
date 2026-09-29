#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILES=(
  lib/app/app_web.dart
  lib/app/widgets/web_global_header_shell.dart
  lib/app/services/web_sync_status_controller.dart
  lib/app/services/web_update_notification_controller.dart
  lib/profile/screens/web_profile_settings_page.dart
)

dart format "${FILES[@]}"

echo "=== WEB SAFE ==="
if grep -nE "dart:io|sqlite3|AppDatabase|app_dependencies.dart" \
  lib/app/widgets/web_global_header_shell.dart \
  lib/app/services/web_sync_status_controller.dart \
  lib/app/services/web_update_notification_controller.dart \
  lib/profile/screens/web_profile_settings_page.dart; then
  echo "ERRO: dependência nativa encontrada." >&2
  exit 1
fi

echo
echo "=== NOTIFICAÇÕES ==="
grep -n "app_updates" lib/app/services/web_update_notification_controller.dart
grep -n "_toggleNotifications" lib/app/widgets/web_global_header_shell.dart
grep -n "notifications_active_outlined" lib/app/widgets/web_global_header_shell.dart

echo
echo "=== SYNC VISUAL ==="
grep -n "Duration(milliseconds: 900)" lib/app/widgets/web_global_header_shell.dart
grep -n "Icons.sync_rounded" lib/app/widgets/web_global_header_shell.dart
grep -n "Icons.cloud_sync_rounded" lib/app/widgets/web_global_header_shell.dart
grep -n "Icons.cloud_done_rounded" lib/app/widgets/web_global_header_shell.dart

echo
echo "=== ANALYZE ==="
flutter analyze "${FILES[@]}"

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: notificações e sync Web validados."


echo
echo "=== CORREÇÃO V2 ==="
TOGGLE_BLOCK="$(grep -n -A 8 "Future<void> _toggleNotifications" \
  lib/app/widgets/web_global_header_shell.dart)"

if printf '%s\n' "$TOGGLE_BLOCK" | \
  grep -q "_notificationsOpen = false"; then
  echo "ERRO: o clique no sino ainda fecha o painel imediatamente." >&2
  exit 1
fi

if grep -n "syncStatus.markChecking" \
  lib/app/services/web_update_notification_controller.dart; then
  echo "ERRO: refresh de notificações ainda interfere na nuvem." >&2
  exit 1
fi

echo "OK: sino e status da nuvem estão desacoplados."
