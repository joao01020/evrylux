#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILES=(
  lib/web_app/services/web_brain_secure_storage.dart
  lib/web_app/services/web_brain_device_service.dart
  lib/web_app/screens/web_brain_access_gate.dart
)

dart format "${FILES[@]}"

echo "=== REGRA DE AUTORIZAÇÃO ==="
grep -n "Sempre consulta o servidor" \
  lib/web_app/screens/web_brain_access_gate.dart
grep -n "if (authorized)" \
  lib/web_app/screens/web_brain_access_gate.dart
grep -n "Revogação é a única situação" \
  lib/web_app/services/web_brain_device_service.dart

echo
echo "=== SEM EXPIRAÇÃO LOCAL ==="
if grep -n "trustedSessionMaxAge" \
  lib/web_app/services/web_brain_device_service.dart; then
  echo "ERRO: ainda existe expiração local por tempo." >&2
  exit 1
fi

echo
echo "=== WEB SAFE ==="
if grep -nE "dart:io|sqlite3|AppDatabase|app_dependencies.dart" \
  "${FILES[@]}"; then
  echo "ERRO: dependência nativa encontrada." >&2
  exit 1
fi

echo
echo "=== ANALYZE ==="
flutter analyze "${FILES[@]}"

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: autorização permanece válida até revogação."
