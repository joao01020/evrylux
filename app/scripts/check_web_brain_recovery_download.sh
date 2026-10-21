#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILE="lib/profile/screens/web_profile_settings_page.dart"

echo "=== PERFIL WEB / CHAVE DE RECUPERAÇÃO ==="
grep -n \
  "WEB BRAIN RECOVERY EXPORT\|Chave de recuperação\|_downloadBrainRecoveryKey\|_brainRecoveryAvailable" \
  "$FILE"

echo
echo "=== SERVIÇO WEB .EVKEY ==="
grep -n \
  "exportRecoveryFile\|registerVerifier" \
  lib/web_app/services/web_brain_recovery_key_service.dart

echo
echo "=== ANALYZE ==="
flutter analyze \
  "$FILE" \
  lib/web_app/services/web_brain_device_service.dart \
  lib/web_app/services/web_brain_recovery_key_service.dart \
  lib/web_app/services/web_brain_secure_storage.dart \
  lib/study/brain/security/keys/brain_key_service.dart \
  lib/study/brain/security/recovery/brain_recovery_file_authorization_service.dart

echo
echo "OK: download .evkey no Perfil Web validado."
