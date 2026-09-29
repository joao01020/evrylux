#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FILES=(
  lib/profile/screens/settings/actions/brain_actions.dart
  lib/profile/screens/settings/sections/profile_settings_shell.dart
  lib/web_app/services/web_brain_device_service.dart \
  lib/web_app/screens/web_brain_access_gate.dart \
  lib/study/brain/devices/services/brain_device_supabase_service.dart
)

dart format "${FILES[@]}"

flutter analyze "${FILES[@]}"

echo
echo "=== Verificações da UI ==="
grep -n "Negar" lib/profile/screens/settings/sections/profile_settings_shell.dart | head
grep -n "_brainAuthorizedDeviceLimit = 3" lib/profile/screens/settings/sections/profile_settings_shell.dart
grep -n "_showAddBrainDeviceDialog" lib/profile/screens/settings/actions/brain_actions.dart | head

echo
echo "=== Migration ==="
test -f supabase/migrations/202609280004_brain_device_limit_three.sql
grep -n "brain_device_limit_reached" supabase/migrations/202609280004_brain_device_limit_three.sql
grep -n "v_authorized_count >= 3" supabase/migrations/202609280004_brain_device_limit_three.sql

echo
echo "Validação local concluída. Aplique o backend com: supabase db push"
