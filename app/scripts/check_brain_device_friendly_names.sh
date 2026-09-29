#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=== STATE ==="
grep -n -A 12 "_renamingBrainDeviceId" \
  lib/profile/screens/profile_settings_page.dart

echo
echo "=== RENAME ACTION ==="
grep -n -A 85 "_showRenameBrainDeviceDialog" \
  lib/profile/screens/settings/actions/brain_actions.dart

echo
echo "=== FINGERPRINT PRIVACY ==="
grep -n -A 45 "fingerprintVisible" \
  lib/profile/screens/settings/sections/profile_settings_shell.dart

echo
echo "=== MIGRATION ==="
test -f supabase/migrations/202609280005_brain_device_custom_names.sql
grep -n "rename_brain_device" \
  supabase/migrations/202609280005_brain_device_custom_names.sql
grep -n "list_brain_device_custom_names" \
  supabase/migrations/202609280005_brain_device_custom_names.sql

echo
echo "=== ANALYZE ==="
flutter analyze \
  lib/profile/screens/profile_settings_page.dart \
  lib/profile/screens/settings/actions/brain_actions.dart \
  lib/profile/screens/settings/sections/profile_settings_shell.dart

echo
echo "OK: UI e código Dart validados."
echo "Lembre-se de aplicar a migration no Supabase antes de testar o rename."
