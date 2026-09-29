#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== INITSTATE REAL ==="
grep -n -A 12 "unawaited(_initialize())" \
  lib/study/brain/screen/brain_screen.dart

echo
echo "=== REALTIME STATE ==="
grep -n -A 18 "_brainRealtimeChannel" \
  lib/study/brain/screen/brain_screen.dart | head -40

echo
echo "=== REALTIME METHODS ==="
grep -n -A 120 "_startBrainRealtimeSync" \
  lib/study/brain/screen/brain_screen_parts/brain_screen_core.dart | head -150

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/study/brain/screen/brain_screen.dart \
  lib/study/brain/screen/brain_screen_parts/brain_screen_core.dart \
  lib/study/brain/runtime/brain_runtime_dependencies_native.dart \
  lib/study/brain/runtime/brain_runtime_dependencies_web.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: Brain Realtime validado."
