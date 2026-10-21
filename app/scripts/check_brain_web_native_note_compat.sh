#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILE="lib/study/brain/vault/mappers/brain_file_vault_mapper.dart"

echo "=== COMPATIBILIDADE DE PAYLOAD DE NOTA ==="
grep -n \
  "model == 'brain_note'\\|data\\['path'\\]\\|data\\['legacy_path'\\]" \
  "$FILE"

echo
echo "=== ANALYZE ==="
flutter analyze \
  "$FILE" \
  lib/study/brain/repositories/brain_repository_web.dart \
  lib/study/brain/repositories/brain_repository_native.dart

echo
echo "OK: Web pode ler payloads brain_note e brain_file."
