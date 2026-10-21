#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== RECOVERY FILE SERVICE ==="
grep -n \
  "decodeRecoveryKeyPackage\\|BrainRecoveryKeyPackageData" \
  lib/study/brain/security/keys/brain_key_service.dart

echo
echo "=== SERVER VERIFIER ==="
grep -n \
  "save_brain_recovery_file_verifier\\|authorize_brain_device_with_recovery_file" \
  lib/study/brain/security/recovery/brain_recovery_file_authorization_service.dart

echo
echo "=== WEB .EVKEY ==="
grep -n \
  "Usar arquivo .evkey\\|_recoverWithRecoveryFile\\|Baixar .evkey" \
  lib/web_app/screens/web_brain_access_gate.dart

echo
echo "=== APP .EVKEY ==="
grep -n \
  "_importBrainRecoveryKeyFile\\|Usar .evkey" \
  lib/profile/screens/settings/actions/brain_actions.dart \
  lib/profile/screens/settings/sections/brain_section.dart

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/study/brain/security/keys/brain_key_service.dart \
  lib/study/brain/security/recovery/brain_recovery_file_authorization_service.dart \
  lib/study/brain/security/recovery/brain_recovery_platform_access.dart \
  lib/profile/screens/profile_settings_page.dart \
  lib/web_app/services/web_brain_recovery_key_service.dart \
  lib/web_app/screens/web_brain_access_gate.dart

echo
echo "OK: fluxo .evkey Web + app validado pelo analyzer."
