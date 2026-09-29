#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILES=(
  lib/study/brain/screen/brain_screen.dart
  lib/brain/visualization/services/brain_visual_state_storage_web.dart
)

dart format "${FILES[@]}"

echo "=== RECONCILIAÇÃO VISUAL ==="
grep -n -A 20 "void _onControllerChanged" \
  lib/study/brain/screen/brain_screen.dart

echo
echo "=== GROWTH STATE WEB ==="
grep -n "growth_state_v1" \
  lib/brain/visualization/services/brain_visual_state_storage_web.dart

echo
echo "=== ANALYZE ==="
flutter analyze "${FILES[@]}"

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: Brain Web visual sincronizado com os conhecimentos carregados."
