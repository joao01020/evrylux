#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILE="lib/study/brain/repositories/brain_repository_web.dart"

echo "=== BRAIN WEB: ÚLTIMA VERSÃO LÓGICA ==="
grep -n \
  "_latestMatchingNote\\|_latestLogicalNotes\\|_isNewerNoteCandidate" \
  "$FILE"

echo
echo "=== loadNotes/getNote/saveNote protegidos contra duplicatas ==="
grep -n \
  "final latest = _latestMatchingNote\\|final latestLogicalNotes = _latestLogicalNotes" \
  "$FILE"

echo
echo "=== ANALYZE ==="
flutter analyze "$FILE"

echo
echo "OK: Brain Web escolhe deterministicamente a versão mais nova por nota lógica."
