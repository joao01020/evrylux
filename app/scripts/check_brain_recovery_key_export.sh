#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

KEY_SERVICE="lib/study/brain/security/keys/brain_key_service.dart"
ACTIONS="lib/profile/screens/settings/actions/brain_actions.dart"
SECTION="lib/profile/screens/settings/sections/brain_section.dart"

echo "=== RECOVERY KEY: CRIPTOGRAFIA ==="
grep -n \
  "exportRecoveryKeyPackage\\|Pbkdf2\\|Xchacha20\\|recoveryKdfIterations" \
  "$KEY_SERVICE"

echo
echo "=== RECOVERY KEY: AUTORIZAÇÃO ==="
grep -n \
  "_currentBrainDeviceCanExportRecoveryKey\\|device.isAuthorized" \
  "$ACTIONS"

echo
echo "=== RECOVERY KEY: UI ==="
grep -n \
  "_buildBrainRecoveryKeyExportSection\\|Baixar chave" \
  "$SECTION"

echo
echo "=== GARANTIA: SEM EXPORTAÇÃO PLAINTEXT DIRETA NA UI ==="
if grep -nE \
  "exportMasterKeyBytes.*FilePicker|base64Encode\\(.*masterKey.*\\).*saveFile" \
  "$ACTIONS" "$SECTION"; then
  echo "ERRO: a UI parece exportar a Master Key diretamente."
  exit 1
else
  echo "OK: a UI grava somente o pacote protegido."
fi

echo
echo "=== ANALYZE ==="
flutter analyze \
  "$KEY_SERVICE" \
  "$ACTIONS" \
  "$SECTION"

echo
echo "OK: exportação protegida da chave de recuperação validada."
