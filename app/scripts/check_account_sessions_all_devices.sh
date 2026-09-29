#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== CONDITIONAL DEVICE IDENTITY ==="
cat lib/profile/security/devices/services/account_device_identity_service.dart

echo
echo "=== WEB IDENTITY ==="
grep -n -A 80 "class AccountDeviceIdentityService" \
  lib/profile/security/devices/services/account_device_identity_service_web.dart

echo
echo "=== WEB PRESENCE ==="
grep -n -A 90 "_webAccountDevicePresenceService" \
  lib/app/app_web.dart | head -120

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/app/app_web.dart \
  lib/profile/security/devices/services/account_device_identity_service.dart \
  lib/profile/security/devices/services/account_device_identity_service_native.dart \
  lib/profile/security/devices/services/account_device_identity_service_web.dart \
  lib/profile/security/devices/services/account_device_presence_service.dart \
  lib/profile/security/devices/repositories/account_device_repository.dart

echo
echo "=== BUILD WEB ==="
./scripts/build_web.sh

echo
echo "OK."
echo
echo "Teste:"
echo "  1. deixe o app Linux logado;"
echo "  2. abra/login no EVRYLUX Web;"
echo "  3. aguarde alguns segundos;"
echo "  4. no Linux, Perfil > Segurança > Sessões e dispositivos > Atualizar;"
echo "  5. devem aparecer Linux Desktop e EVRYLUX Web."
