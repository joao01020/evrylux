#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILE="lib/study/brain/repositories/brain_repository_web.dart"

dart format "$FILE"

echo "=== ORPHAN CONCEPT SEARCH BRIDGE ==="
grep -n -A 80 "_orphanConceptSearchNotes" "$FILE"

echo
echo "=== LOAD NOTES ==="
grep -n -A 50 "Future<List<Map<String, dynamic>>> loadNotes" "$FILE"

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/study/brain/repositories/brain_repository_web.dart \
  lib/study/brain/controllers/brain_controller.dart \
  lib/study/brain/screen/brain_screen.dart \
  lib/study/brain/screen/brain_screen_parts/brain_screen_visual_search.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK: conceitos standalone agora entram na busca principal."
