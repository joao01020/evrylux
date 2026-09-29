#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== TEXTO ==="
grep -n "Este navegador perdeu a chave local usada para acessar seu Cérebro." \
  lib/web_app/screens/web_brain_access_gate.dart

echo
echo "=== NATIVE PRE-PULL ==="
grep -n -A 20 "Future<void> syncBrainBeforeLoad" \
  lib/study/brain/runtime/brain_runtime_dependencies_native.dart

echo
echo "=== WEB RUNTIME ==="
grep -n -A 10 "Future<void> syncBrainBeforeLoad" \
  lib/study/brain/runtime/brain_runtime_dependencies_web.dart

echo
echo "=== SCREEN ==="
grep -n -A 50 "TWO-WAY CLOUD SYNC" \
  lib/study/brain/screen/brain_screen_parts/brain_screen_core.dart

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/web_app/screens/web_brain_access_gate.dart \
  lib/study/brain/runtime/brain_runtime_dependencies_native.dart \
  lib/study/brain/runtime/brain_runtime_dependencies_web.dart \
  lib/study/brain/screen/brain_screen.dart \
  lib/study/brain/screen/brain_screen_parts/brain_screen_core.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: Brain bidirecional preparado."
