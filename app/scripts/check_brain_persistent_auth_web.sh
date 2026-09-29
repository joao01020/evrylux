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
flutter analyze "${FILES[@]}"

echo
echo "=== Persistência Web ==="
grep -n "trustedSessionMaxAge" lib/web_app/services/web_brain_device_service.dart
grep -n "saveTrustedAccess" lib/web_app/services/web_brain_secure_storage.dart
grep -n "revalidateTrustedSession" lib/web_app/services/web_brain_device_service.dart
grep -n "Só será necessário autorizar novamente" lib/web_app/screens/web_brain_access_gate.dart

echo
echo "Validação local concluída."

echo
echo "=== Pending Web ==="
grep -n "solicitação pending válida" lib/web_app/screens/web_brain_access_gate.dart
grep -n "registerOrRefresh(vaultId: vaultId)" lib/web_app/screens/web_brain_access_gate.dart
