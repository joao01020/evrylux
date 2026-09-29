#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILES=(
  lib/app/app_web.dart
  lib/app/widgets/web_global_header_shell.dart
  lib/profile/screens/web_profile_settings_page.dart
)

dart format "${FILES[@]}"

echo "=== IMPORTS WEB-SAFE ==="
if grep -n "profile_settings_page.dart" \
  lib/app/widgets/web_global_header_shell.dart; then
  echo "ERRO: header ainda importa a página nativa." >&2
  exit 1
fi

grep -n "web_profile_settings_page.dart" \
  lib/app/widgets/web_global_header_shell.dart

if grep -nE "dart:io|app_dependencies.dart|sqlite3|AppDatabase" \
  lib/profile/screens/web_profile_settings_page.dart; then
  echo "ERRO: página Web contém dependência nativa." >&2
  exit 1
fi

echo
echo "=== ANALYZE ==="
flutter analyze "${FILES[@]}"

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: Perfil e configurações não puxa SQLite/FFI no Web."
