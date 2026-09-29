#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== WEB PRESENCE BRIDGE ==="
grep -n -A 150 "_WebAccountPresenceBridge" lib/app/app_web.dart | head -190

echo
echo "=== WEB SESSION IDENTITY ==="
cat lib/profile/security/devices/services/account_device_identity_service.dart
grep -n -A 60 "class AccountDeviceIdentityService" \
  lib/profile/security/devices/services/account_device_identity_service_web.dart

echo
echo "=== REPOSITORY DIAGNOSTICS ==="
grep -n "\\[ACCOUNT DEVICE\\]\\[REGISTER\\]\\|\\[ACCOUNT DEVICE\\]\\[LIST\\]" \
  lib/profile/security/devices/repositories/account_device_repository.dart

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/app/app_web.dart \
  lib/profile/security/devices/repositories/account_device_repository.dart \
  lib/profile/security/devices/services/account_device_identity_service.dart \
  lib/profile/security/devices/services/account_device_identity_service_native.dart \
  lib/profile/security/devices/services/account_device_identity_service_web.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK."
echo
echo "Depois do deploy Web, abra o console do navegador e procure:"
echo "  [ACCOUNT DEVICE][WEB] iniciando presença"
echo "  [ACCOUNT DEVICE][REGISTER]"
echo "  [ACCOUNT DEVICE][WEB] registrado=true dispositivosAtivos=2"
