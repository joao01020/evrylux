#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PROFILE="lib/profile/screens/web_profile_settings_page.dart"
MANAGEMENT="lib/web_app/services/web_brain_device_management_service.dart"

echo "=== PERFIL WEB DO CÉREBRO ==="
grep -n \
  "Modo de dados\|Proteção do Cérebro\|Detalhes técnicos\|Chave de recuperação\|Dispositivos do Cérebro\|Proteção dos dados\|Recuperar em outro dispositivo" \
  "$PROFILE"

echo
echo "=== AÇÕES DE DISPOSITIVO ==="
grep -n \
  "approvePendingDevice\|revokeDevice\|renameDevice\|listCustomNames" \
  "$MANAGEMENT"

echo
echo "=== SEM DART:IO NO PERFIL WEB ==="
if grep -n "dart:io" "$PROFILE" "$MANAGEMENT"; then
  echo "ERRO: dart:io encontrado em código Web."
  exit 1
fi

echo
echo "=== ANALYZE ==="
flutter analyze \
  "$PROFILE" \
  "$MANAGEMENT" \
  lib/web_app/services/web_brain_device_service.dart \
  lib/web_app/services/web_brain_recovery_key_service.dart \
  lib/web_app/services/web_brain_secure_storage.dart \
  lib/study/brain/devices/services/brain_device_supabase_service.dart \
  lib/study/brain/devices/models/brain_device_record.dart \
  lib/study/brain/security/keys/brain_key_service.dart

echo
echo "OK: painel Web do Cérebro validado."
