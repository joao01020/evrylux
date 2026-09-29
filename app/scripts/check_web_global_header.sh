#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILES=(
  lib/app/app_web.dart
  lib/app/widgets/web_global_header_shell.dart
  lib/profile/screens/profile_settings_page.dart
)

dart format \
  lib/app/app_web.dart \
  lib/app/widgets/web_global_header_shell.dart

flutter analyze "${FILES[@]}"

echo
echo "=== NAVEGAÇÃO REAL DE PERFIL ==="
grep -n "navigatorKey: webNavigatorKey" lib/app/app_web.dart
grep -n "ProfileSettingsPage" lib/app/widgets/web_global_header_shell.dart
grep -n "ProfileSettingsSection.preferences" lib/app/widgets/web_global_header_shell.dart
grep -n "ProfileSettingsSection.security" lib/app/widgets/web_global_header_shell.dart

echo
echo "=== OVERLAY SAFETY ==="
if grep -n "Tooltip(" lib/app/widgets/web_global_header_shell.dart; then
  echo "ERRO: Tooltip ainda existe no header." >&2
  exit 1
fi

if grep -n "showModalBottomSheet" lib/app/widgets/web_global_header_shell.dart; then
  echo "ERRO: showModalBottomSheet ainda existe no header." >&2
  exit 1
fi

echo
echo "OK: Preferências e Segurança abrem a ProfileSettingsPage REAL."
